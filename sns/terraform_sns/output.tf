output "input_bucket_id" {
  value = module.input.input_bucket_id
}

output "output_bucket_id" {
  value = module.output.output_bucket_id
}

output "sns_topic_arn" {
  value = module.compute.sns_topic_arn
}
