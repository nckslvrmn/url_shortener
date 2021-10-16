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
    actions = [
      "dynamodb:DeleteItem",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem"
    ]
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


# api gateway role
data "aws_iam_policy_document" "apigateway_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = [
        "apigateway.amazonaws.com",
      ]
    }
  }
}

data "aws_iam_policy_document" "apigateway_bucket_access" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.url_shortener_site.arn}/*"]
  }
}

resource "aws_iam_role" "apigateway" {
  name               = "url_shortener_apigateway_role"
  assume_role_policy = data.aws_iam_policy_document.apigateway_assume.json
}

resource "aws_iam_role_policy" "apigateway_s3_bucket" {
  name   = "s3_bucket"
  role   = aws_iam_role.apigateway.id
  policy = data.aws_iam_policy_document.apigateway_bucket_access.json
}
