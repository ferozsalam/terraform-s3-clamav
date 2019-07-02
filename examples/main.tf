provider "aws" {
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
    region     = "${var.region}"
}

resource "aws_s3_bucket" "bucket-to-scan" {
    count = "${length(var.buckets-to-scan)}"
    bucket = "${element(var.buckets-to-scan, count.index)}"
    acl    = "private"
}

module "terraform-test" {
  source  = "/home/feroz/terraclam-s3/"
  clamav-definitions-bucket = "clamav-definitions"
  buckets-to-scan            = "${var.buckets-to-scan}"
}
