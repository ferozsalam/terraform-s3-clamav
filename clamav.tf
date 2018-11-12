// Bucket to hold clamav definitions
resource "aws_s3_bucket" "clamav-definitions" {
    bucket = "${var.clamav-definitions-bucket}"
    acl    = "private"
}

resource "aws_iam_role" "clamav" {
    name = "clamav"

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

resource "aws_iam_policy" "clamav" {
    name        = "clamav"

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
            "s3:GetObject",
            "s3:GetObjectTagging",
            "s3:PutObject",
            "s3:PutObjectTagging",
            "s3:PutObjectVersionTagging"
         ],
         "Effect":"Allow",
         "Resource":"arn:aws:s3:::${aws_s3_bucket.clamav-definitions.bucket}/*"
      }
   ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "clamav" {
    role       = "${aws_iam_role.clamav.name}"
    policy_arn = "${aws_iam_policy.clamav.arn}"
}

resource "aws_lambda_function" "update-clamav-definitions" {
    filename         = "${path.module}/lambda.zip"
    function_name    = "update-clamav-definitions"
    role             = "${aws_iam_role.clamav.arn}"
    handler          = "update.lambda_handler"
    source_code_hash = "${base64sha256(file("${path.module}/lambda.zip"))}"
    runtime          = "python2.7"
    timeout          = 300
    memory_size      = 512

    environment {
        variables = {
            AV_DEFINITION_S3_BUCKET = "${aws_s3_bucket.clamav-definitions.bucket}"
        }
    }
}

// Cloudwatch event that fires every three hours
resource "aws_cloudwatch_event_rule" "every-three-hours" {
    name = "every-three-hours"
    description = "Fires every three hours"
    schedule_expression = "rate(3 hours)"
}

// A rule to call a lambda function when the Cloudwatch event fires
resource "aws_cloudwatch_event_target" "update-clamav-definitions" {
    rule = "${aws_cloudwatch_event_rule.every-three-hours.name}"
    target_id = "update-clamav-definitions"
    arn = "${aws_lambda_function.update-clamav-definitions.arn}"
}

// Permissions to allow the Cloudwatch event to call our Lambda function
resource "aws_lambda_permission" "allow_cloudwatch_to_update_antivirus" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.update-clamav-definitions.function_name}"
    principal = "events.amazonaws.com"
    source_arn = "${aws_cloudwatch_event_rule.every-three-hours.arn}"
}

