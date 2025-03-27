resource "aws_sns_topic" "file_upload_topic" {
  name = "file-upload-topic"
}

resource "aws_s3_bucket_notification" "input_bucket_notification" {
  bucket = var.input_bucket_id

  topic {
    topic_arn = aws_sns_topic.file_upload_topic.arn
    events    = ["s3:ObjectCreated:*"]
  }
}

resource "aws_lambda_function" "file_processor_lambda" {
  function_name = "fileProcessorLambda"
  role          = aws_iam_role.lambda_exec.arn
  runtime       = "python3.8"
  handler       = "lambda_function.lambda_handler"
  filename      = "lambda_function.zip"

  environment {
    variables = {
      OUTPUT_BUCKET = var.output_bucket_id
    }
  }
}

resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.file_processor_lambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.file_upload_topic.arn
}

resource "aws_sns_topic_subscription" "sns_lambda_subscription" {
  topic_arn = aws_sns_topic.file_upload_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.file_processor_lambda.arn
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "lambda_s3_policy" {
  name        = "lambda_s3_access"
  description = "Allows Lambda to read from input bucket and write to output bucket"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": [
        "${var.input_bucket_arn}/*",
        "${var.output_bucket_arn}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_s3_policy.arn
}
