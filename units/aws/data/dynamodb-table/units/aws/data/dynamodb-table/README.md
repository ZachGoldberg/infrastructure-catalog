# DynamoDB Table (game data)

Opinionated single-table DynamoDB module for JSON game data.

## Defaults
- **On-demand billing** (`PAY_PER_REQUEST`) — scales to zero cost, no capacity planning.
- **Point-in-time recovery: ON** — continuous backup, ~35-day restore window. Restores create a NEW table; repoint the consumer.
- **Deletion protection: ON** — guards against accidental destroy of stateful data.
- **Server-side encryption: ON** (AWS-managed key).

## Key schema
Generic `PK` (partition) / `SK` (sort), both strings. Intended pattern for multi-app sharing:
`PK = APP#<appId>#PLAYER#<playerId>`, `SK = <recordType>#<id>`. This lets two apps share one
table now and split per-app cleanly later.
