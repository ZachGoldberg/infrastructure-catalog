"""Game-data CRUD handler for API Gateway HTTP API (payload format v2).

Data model (single-table, multi-app):
  PK = APP#<appId>#PLAYER#<playerId>
  SK = SAVE#<saveId>

Writes are conditional + idempotent so a retrying iOS client cannot clobber
newer state:
  - Each item carries a numeric `version`.
  - PUT requires the caller's `expected_version` to match the stored version
    (optimistic concurrency); the stored version is then incremented.
  - A client-supplied `request_id` makes retries safe (same write applied once).
"""
import json
import os

import boto3
from botocore.exceptions import ClientError

_TABLE = boto3.resource("dynamodb").Table(os.environ["TABLE_NAME"])


def _resp(status, body):
    return {
        "statusCode": status,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body),
    }


def _pk(app_id, player_id):
    return f"APP#{app_id}#PLAYER#{player_id}"


def handler(event, _context):
    method = event.get("requestContext", {}).get("http", {}).get("method", "")
    qs = event.get("queryStringParameters") or {}
    app_id = qs.get("app_id")
    player_id = qs.get("player_id")
    save_id = qs.get("save_id", "default")

    if not app_id or not player_id:
        return _resp(400, {"error": "app_id and player_id are required"})

    pk = _pk(app_id, player_id)
    sk = f"SAVE#{save_id}"

    if method == "GET":
        return _get(pk, sk)
    if method in ("PUT", "POST"):
        return _put(event, pk, sk)
    if method == "DELETE":
        return _delete(pk, sk)
    return _resp(405, {"error": f"method {method} not allowed"})


def _get(pk, sk):
    res = _TABLE.get_item(Key={"PK": pk, "SK": sk})
    item = res.get("Item")
    if not item:
        return _resp(404, {"error": "not found"})
    return _resp(200, item)


def _put(event, pk, sk):
    try:
        payload = json.loads(event.get("body") or "{}")
    except json.JSONDecodeError:
        return _resp(400, {"error": "body must be valid JSON"})

    data = payload.get("data")
    if data is None:
        return _resp(400, {"error": "`data` (JSON game state) is required"})

    request_id = payload.get("request_id")
    expected_version = payload.get("expected_version")

    item = {
        "PK": pk,
        "SK": sk,
        "data": data,
        "version": 1,
        "last_request_id": request_id,
    }

    try:
        if expected_version is None:
            # First write only: must not already exist.
            _TABLE.put_item(
                Item=item,
                ConditionExpression="attribute_not_exists(PK)",
            )
        else:
            # Optimistic concurrency: stored version must match, then bump.
            # Idempotent retry: if same request_id already applied, treat as success.
            existing = _TABLE.get_item(Key={"PK": pk, "SK": sk}).get("Item")
            if existing and existing.get("last_request_id") == request_id and request_id is not None:
                return _resp(200, existing)
            item["version"] = int(expected_version) + 1
            _TABLE.put_item(
                Item=item,
                ConditionExpression="version = :v",
                ExpressionAttributeValues={":v": int(expected_version)},
            )
    except ClientError as exc:
        if exc.response["Error"]["Code"] == "ConditionalCheckFailedException":
            return _resp(409, {"error": "version conflict: stale game state, re-read before writing"})
        raise

    return _resp(200, item)


def _delete(pk, sk):
    _TABLE.delete_item(Key={"PK": pk, "SK": sk})
    return _resp(204, {})
