resource "aws_dynamodb_table" "url_shortener" {
  name         = "URLDB"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "short_url_id"

  attribute {
    name = "short_url_id"
    type = "S"
  }

  ttl {
    enabled        = true
    attribute_name = "ttl"
  }

  tags = {
    Name = "URLDB"
  }
}
