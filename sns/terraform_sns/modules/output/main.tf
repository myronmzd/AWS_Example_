resource "aws_s3_bucket" "output_bucket" {
  bucket = var.output_bucket_name
}

