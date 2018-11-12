# terraclam-s3

Terraform module that allows antivirus scanning of S3 buckets on object creation
by clamav.

Pretty rough-and-ready, but does the job.

The architecture of the module and the scanning function is provided by
[Upside Travel](https://github.com/upsidetravel/bucket-antivirus-function). The
library build was created in November 2018.

Clamav definitions are updated every three hours.

Major current limitation is that it only works with a single folder.
