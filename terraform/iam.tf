# lambda role
data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com",
      ]
    }
  }
}

data "aws_iam_policy_document" "dynamo_access" {
  statement {
    actions   = ["dynamodb:PutItem"]
    resources = [aws_dynamodb_table.url_shortener.arn]
  }
}

resource "aws_iam_role" "url_shortener" {
  name               = "url_shortener_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy_attachment" "basic_exec" {
  role       = aws_iam_role.url_shortener.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "dynamo_table" {
  name   = "dynamo_table"
  role   = aws_iam_role.url_shortener.id
  policy = data.aws_iam_policy_document.dynamo_access.json
}

# api gateway role (direct DynamoDB GetItem for redirects + S3 GetObject for static)
data "aws_iam_policy_document" "apig_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "apig_access" {
  statement {
    actions   = ["dynamodb:GetItem"]
    resources = [aws_dynamodb_table.url_shortener.arn]
  }
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.static.arn}/*"]
  }
}

resource "aws_iam_role" "apig" {
  name               = "url_shortener_apig_role"
  assume_role_policy = data.aws_iam_policy_document.apig_assume.json
}

resource "aws_iam_role_policy" "apig_access" {
  name   = "apig_access"
  role   = aws_iam_role.apig.id
  policy = data.aws_iam_policy_document.apig_access.json
}
