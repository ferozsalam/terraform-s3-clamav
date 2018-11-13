variable "access_key" {}
provider "aws" {
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
    region     = "${var.region}"
}

resource "aws_s3_bucket" "bucket-to-scan" {
    bucket = "${var.bucket-to-scan}"
    acl    = "private"
}

module "terraform-test" {
  source  = "/home/feroz/terraclam-s3/"
  clamav-definitions-bucket = "clamav-definitions"
  bucket-to-scan            = "${var.bucket-to-scan}"
  bucket-to-scan-arn        = "${aws_s3_bucket.bucket-to-scan.arn}"
}
