# lambda-scheduled-notifier

A scheduled Lambda that runs on an EventBridge timer and sends an email via SES.

## Design notes
- Python 3.12 / arm64 / 128MB. Zip package.
- Tight inline IAM role: logs scoped to this function's own log group; `ses:SendEmail` scoped to the verified SES identity with a `ses:FromAddress` condition. No `Resource: *`, no VPC, no KMS. Confused-deputy conditions (`aws:SourceAccount`) on the assume-role policy.
- Log group pre-created at 14-day retention so `logs:CreateLogGroup` can be dropped.
- Handler raises on a missing SES `MessageId` so failed sends register as Lambda errors.

## Alarms (`create_alarms`, default true)
- **Errors** – crash/timeout/SES throw.
- **missed-invocation** – `Invocations < 1` over 25h with `treat_missing_data = breaching`; catches a disabled/missed schedule, which an error alarm cannot.
- **ses-bounce** – SES `Bounce > 0`.

If `alarm_sns_topic_arn` is empty, a topic is created. Subscribe an out-of-band channel (e.g. Slack) so an SES outage can't blind its own alerting.

## Prerequisites (account-level, not managed here)
- Verify the `ses_from_address` identity in the target region. You will likely be in the SES sandbox; fine when sender and recipient are the same verified address.

## Inputs
| Name | Description | Default |
|------|-------------|---------|
| function_name | Lambda function name | — |
| aws_region | Region | — |
| account_id | Account ID (confused-deputy conditions) | — |
| ses_from_address | Verified SES sender (config, not a secret) | — |
| ses_to_address | Recipient; defaults to ses_from_address | "" |
| schedule_expression | EventBridge schedule | rate(1 day) |
| schedule_enabled | Enable the schedule | true |
| log_retention_days | Log retention | 14 |
| create_alarms | Create alarms | true |
| alarm_sns_topic_arn | Existing SNS topic; created if empty | "" |
