resource "aws_s3_bucket" "url_shortener_site" {
  bucket = var.domain_name
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "site_block_all" {
  bucket = aws_s3_bucket.url_shortener_site.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
