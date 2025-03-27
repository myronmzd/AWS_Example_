# Create an SNS topic for notifications
resource "aws_sns_topic" "file_processing_topic" {
  name = "file-processing-topic"
}

# Email subscription for SNS topic
resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.file_processing_topic.arn
  protocol  = "email"
  endpoint  = var.email_endpoint  # Add this variable to your variables.tf
}

# Lambda Function
resource "aws_lambda_function" "file_processor_lambda" {
  filename         = "lambda_function.zip"
  function_name    = "fileProcessorLambda"
  role            = aws_iam_role.lambda_exec.arn
  handler         = "lambda_function.lambda_handler"
  runtime         = "python3.8"

  environment {
    variables = {
      OUTPUT_BUCKET = var.output_bucket_id
      SNS_TOPIC_ARN = aws_sns_topic.file_processing_topic.arn
    }
  }
}

# S3 trigger for Lambda (Input bucket)
resource "aws_s3_bucket_notification" "input_bucket_trigger" {
  bucket = var.input_bucket_id

  lambda_function {
    lambda_function_arn = aws_lambda_function.file_processor_lambda.arn
    events             = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}

# S3 notification for output bucket to SNS
resource "aws_s3_bucket_notification" "output_bucket_notification" {
  bucket = var.output_bucket_id

  topic {
    topic_arn = aws_sns_topic.file_processing_topic.arn
    events    = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_sns_topic_policy.allow_s3_notification]
}

# Allow S3 to invoke Lambda
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.file_processor_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = var.input_bucket_arn
}

# SNS Topic Policy to allow S3 notifications
resource "aws_sns_topic_policy" "allow_s3_notification" {
  arn = aws_sns_topic.file_processing_topic.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowS3ToPublishToSNS"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.file_processing_topic.arn
        Condition = {
          ArnLike = {
            "aws:SourceArn": var.output_bucket_arn
          }
        }
      }
    ]
  })
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for Lambda to access S3 and SNS
resource "aws_iam_policy" "lambda_exec_policy" {
  name = "lambda_exec_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.input_bucket_arn,
          "${var.input_bucket_arn}/*",
          var.output_bucket_arn,
          "${var.output_bucket_arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = [aws_sns_topic.file_processing_topic.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = ["arn:aws:logs:*:*:*"]
      }
    ]
  })
}

# Attach policy to Lambda role
resource "aws_iam_role_policy_attachment" "lambda_exec_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_exec_policy.arn
}


