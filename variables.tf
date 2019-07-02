variable "clamav-definitions-bucket" {
    description = "The name of the bucket which will contain clamav definitions"
}

variable "buckets-to-scan" {
    type = "list"
    description = "The buckets which need scanning"
}
