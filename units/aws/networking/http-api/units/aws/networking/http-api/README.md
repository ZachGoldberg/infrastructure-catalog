# API Gateway HTTP API (game-data)

HTTP API (v2) fronting the game-data Lambda. Chosen over REST API: ~70% cheaper
per request, lower latency, and native JWT-authorizer support so Cognito or
Sign in with Apple drops in later with no rebuild.

## Defaults
- **`$default` route** proxies all paths to the Lambda (AWS_PROXY, payload v2).
- **Access logging** as JSON to a dedicated 30-day log group.
- **Default-route throttling** (burst 20 / rate 10 rps) so the currently
  unauthenticated endpoint has abuse and cost protection before auth lands.
- **Detailed metrics enabled** for per-route CloudWatch metrics.

## Adding auth later
This API is auth-ready. When Cognito / Sign in with Apple is chosen, add an
`aws_apigatewayv2_authorizer` (JWT) and set `authorization_type = "JWT"` on the
route. No change to the Lambda or table is required.
