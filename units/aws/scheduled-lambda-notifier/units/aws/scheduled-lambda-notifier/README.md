# Scheduled Lambda Notifier

Runs a Lambda function on a cron schedule (EventBridge Scheduler) and delivers its
output to an email recipient via an SNS topic subscription.

## What it creates
- Lambda function (default 128MB, no VPC, CloudWatch Logs to a pre-created log group)
- EventBridge Scheduler schedule with an explicit cron expression + timezone
- SNS topic with one or more email subscriptions (requires one-time confirmation click)
- SQS dead-letter queue for the Lambda
- CloudWatch alarm on Lambda `Errors`
- Two least-privilege IAM roles (Lambda execution, Scheduler invoke) with
  confused-deputy `aws:SourceAccount` / `aws:SourceArn` trust conditions

## Notes
- `schedule_expression_timezone` is required so "9am" does not drift with DST.
- Email subscriptions must be confirmed by the recipient before delivery starts.
- The SNS topic policy limits `Publish` to the Lambda role and restricts `Subscribe`.
