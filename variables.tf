variable "clamav-definitions-bucket" {
    description = "The name of the bucket which will contain clamav definitions"
}

variable "bucket-to-scan" {
    description = "The bucket which needs scanning"
}

variable "bucket-to-scan-arn" {
    description = "The ARN of the bucket which needs scanning"
}
