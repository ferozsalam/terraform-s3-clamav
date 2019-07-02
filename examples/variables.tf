variable "access_key" {}
variable "secret_key" {}
variable "region" {}

variable "buckets-to-scan" {
    type = "list"
    default = ["terraform-files-to-scan", "second-tf-files-to-scan"]
}

