variable "input_bucket_id" {
  description = "ID of the input S3 bucket"
}

variable "input_bucket_arn" {
  description = "ARN of the input S3 bucket"
}

variable "output_bucket_id" {
  description = "ID of the output S3 bucket"
}

variable "output_bucket_arn" {
  description = "ARN of the output S3 bucket"
}

variable "email_endpoint" {
  type        = string
  description = "Email address for SNS notifications"
}
