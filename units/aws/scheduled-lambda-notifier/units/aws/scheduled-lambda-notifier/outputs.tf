output "function_name" {
  value = var.name
}

output "sns_topic_arn" {
  value = aws_sns_topic.this.arn
}

output "dlq_arn" {
  value = aws_sqs_queue.dlq.arn
}
