# Lambda Function (game-data API)

Python 3.12 Lambda backing the game-data HTTP API. **No VPC** — it reaches
DynamoDB over the AWS API, so adding a VPC would only cost a NAT gateway and
cold-start latency.

## Security / ops defaults
- **Least-privilege role**: scoped to one table ARN (+ `index/*`) and exactly five
  DynamoDB actions (GetItem/PutItem/UpdateItem/DeleteItem/Query). No `dynamodb:*`,
  no `Scan`, no account-wide `logs:*`.
- **Explicit log group** with 30-day retention (no never-expire default).
- **X-Ray active tracing** — auto-instruments the DynamoDB calls.

## Handler behaviour (`src/handler.py`)
CRUD over `GET/PUT/DELETE` keyed by `app_id` + `player_id` (+ optional `save_id`).
Writes are **conditional + idempotent**: an item `version` enforces optimistic
concurrency (stale writes get 409), and a client `request_id` makes retries safe.
This is the layer that stops a retrying iOS client from clobbering newer saves.
