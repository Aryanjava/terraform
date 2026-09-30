resource "random_id" "bucket_suffix" {
    byte_length = 4
}

resource "aws_s3_bucket" "app" {
    bucket = "${var.project_name}-app-bucket-${random_id.bucket_suffix.hex}"

    tags = { Name = "${var.project_name}-app-bucket" }
}

#versioning protectection against accidental overwrite/delete -
#every version of an object is kept and recoverable

resource "aws_s3_bucket_versioning" "app" {
    bucket  = aws_s3_bucket.app.id
    versioning_configuration {
        status = "Enabled"
    }
}

#Block every avenue of public access. This will be default unless we are building public
#accessable website or bucket

resource "aws_s3_bucket_public_access_block" "app" {
    bucket = aws_s3_bucket.app.id

    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
} 


#object encryption at rest by default (AES 256)

resource "aws_s3_server_side_encryption_configuration" "app" {
    bucket = aws_s3_bucket.app.id

    rule{
        apply_server_side_encryption_by_default {
            sse_algorithm = "AES256"
        }
    }
}