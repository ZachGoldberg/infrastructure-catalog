# prime-emailer

A scheduled AWS Lambda that computes the Nth prime number (default: the 10th, which is **29**) and emails it once a day via SES.

## Architecture

```
EventBridge Scheduler (cron, timezone-aware)
        -> Lambda (Python, computes Nth prime, formats email)
        -> SES SendEmail -> recipient
```

- **Compute**: Lambda, 128 MB, Python 3.12. Effectively free at one invocation/day.
- **Email**: SES `SendEmail` authenticated via the Lambda execution role. **No secrets** — no SMTP credentials anywhere.
- **Schedule**: EventBridge Scheduler with native IANA timezone support (DST-safe), unlike legacy CloudWatch Events rules.

## SES sandbox note

By default SES accounts are in the **sandbox**, where you can only send to verified addresses. This module verifies `sender_email` as an identity. If `sender_email == recipient_email` (e.g. both `zach@gruntwork.io`), the single verification covers both ends and you never need to request SES production access. You must click the verification link AWS emails you before the first send will succeed.

## IAM

The execution role grants only:
- `logs:CreateLogStream` / `logs:PutLogEvents` on the function's own log group (log group is pre-created in IaC, so `CreateLogGroup` is not needed).
- `ses:SendEmail` scoped to the single verified identity ARN, with conditions pinning the From address and restricting recipients to `recipient_email`.

## Inputs

| Name | Description | Default |
|------|-------------|---------|
| `function_name` | Function name / resource prefix | `prime-emailer` |
| `recipient_email` | Who receives the email | (required) |
| `sender_email` | SES-verified From address | (required) |
| `prime_index` | Which prime to compute (1-indexed) | `10` |
| `schedule_expression` | Scheduler cron/rate expression | `cron(0 9 * * ? *)` |
| `schedule_timezone` | IANA timezone for the schedule | `America/Los_Angeles` |
| `log_retention_in_days` | CloudWatch Logs retention | `14` |
