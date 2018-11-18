// Create an IAM role for the scanner lambda function
resource "aws_iam_role" "bucket-antivirus-scan" {
    name = "bucket-antivirus-scan"

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

// Create an IAM policy for the scanner lambda function
resource "aws_iam_policy" "bucket-antivirus-scan" {
    name        = "bucket-antivirus-scan"

    policy = <<EOF
{
   "Version":"2012-10-17",
   "Statement":[
      {
         "Effect":"Allow",
         "Action":[
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
         ],
         "Resource":"*"
      },
      {
         "Action":[
            "s3:*"
         ],
         "Effect":"Allow",
         "Resource":"*"
      }
   ]
}
EOF
}

// Bind the policy to the role
resource "aws_iam_role_policy_attachment" "attach-scan-role-policy" {
    role       = "${aws_iam_role.bucket-antivirus-scan.name}"
    policy_arn = "${aws_iam_policy.bucket-antivirus-scan.arn}"
}

// Add the lambda function
resource "aws_lambda_function" "scan-file" {
    filename         = "${path.module}/lambda.zip"
    function_name    = "scan-bucket-file"
    role             = "${aws_iam_role.bucket-antivirus-scan.arn}"
    handler          = "scan.lambda_handler"
    source_code_hash = "${base64sha256(file("${path.module}/lambda.zip"))}"
    runtime          = "python2.7"
    timeout          = 300
    memory_size      = 1024

    environment {
        variables = {
        AV_DEFINITION_S3_BUCKET = "${aws_s3_bucket.clamav-definitions.bucket}"
        }
    }
}

// Allow the lambda function to access the S3 bucket
resource "aws_lambda_permission" "allow_terraform_bucket" {
    statement_id = "AllowExecutionFromS3Bucket"
    action = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.scan-file.arn}"
    principal = "s3.amazonaws.com"
    source_arn = "${var.bucket-to-scan-arn}"
}

// Allow the S3 bucket to send notifications to the lambda function
resource "aws_s3_bucket_notification" "new-file-notification" {
    bucket = "${var.bucket-to-scan}"

    lambda_function {
        lambda_function_arn = "${aws_lambda_function.scan-file.arn}"
        events              = ["s3:ObjectCreated:*"]
    }
}

data "aws_caller_identity" "current" {}

// Add a policy to the bucket that prevents download of infected files
resource "aws_s3_bucket_policy" "bucket-to-scan" {
  bucket = "${var.bucket-to-scan}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "NotPrincipal": {
          "AWS": [
              "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
              "arn:aws:sts::${data.aws_caller_identity.current.account_id}:assumed-role/${aws_iam_role.bucket-antivirus-scan.name}/${aws_lambda_function.scan-file.function_name}",
              "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.bucket-antivirus-scan.name}"
          ]
      },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${var.bucket-to-scan}/*",
      "Condition": {
          "StringNotEquals": {
              "s3:ExistingObjectTag/av-status": "CLEAN"
          }
      }
    }
  ]
}
POLICY
}
