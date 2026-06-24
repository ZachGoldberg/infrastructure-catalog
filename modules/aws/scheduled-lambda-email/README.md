# scheduled-lambda-email

A self-contained, timezone-aware scheduled Lambda that computes the Nth prime
number and emails it via SES on a cron schedule.

## What it creates

- **Lambda** (`python3.12`) — computes the Nth prime, sends one email via SES.
  A failed send is re-raised so it shows up on the Errors alarm.
- **EventBridge Scheduler** — fires the Lambda on `schedule_expression`, evaluated
  in `schedule_timezone` (default `America/New_York`), so 9am means *local* 9am.
- **Least-privilege IAM** — exec role can only `ses:SendEmail` as/to the one
  verified identity, and write to its own log group. Scheduler role can only
  invoke this function.
- **Observability** — log group with bounded retention + three alarms (Errors,
  did-not-run / missing invocations, SES bounce) to an SNS email topic.

## Prerequisites

- **SES identity verification:** `email_address` must be a verified SES identity
  in this region. Sender == recipient, so SES sandbox is fine; no sandbox-exit
  needed.
- Confirm the SNS subscription email when it arrives (one-time click).

## Key variables

| Variable | Default | Notes |
|---|---|---|
| `email_address` | (required) | Verified SES identity; sender and recipient. |
| `prime_index` | `10` | The 10th prime is 29. |
| `schedule_expression` | `cron(0 9 * * ? *)` | Evaluated in `schedule_timezone`. |
| `schedule_timezone` | `America/New_York` | IANA tz so 9am is local. |
| `log_retention_days` | `14` | |
| `alarm_email` | `email_address` | Where alarms go. |
