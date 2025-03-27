resource "aws_s3_bucket" "output_bucket" {
  bucket = var.output_bucket_name
}

# Make output bucket public
resource "aws_s3_bucket_public_access_block" "output_bucket_public_access" {
  bucket = aws_s3_bucket.output_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Output bucket policy for public read access
resource "aws_s3_bucket_policy" "output_bucket_policy" {
  bucket = aws_s3_bucket.output_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.output_bucket.arn}/*"
      }
    ]
  })
  depends_on = [aws_s3_bucket_public_access_block.output_bucket_public_access]
}
