data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda_function.zip"

  source {
    content  = file("${path.module}/../lambda.py")
    filename = "lambda.py"
  }

  source {
    content  = file("${path.module}/../static/index.html")
    filename = "static/index.html"
  }
}

resource "aws_lambda_function" "url_shortener" {
  filename         = "${path.module}/lambda_function.zip"
  function_name    = "url_shortener"
  role             = aws_iam_role.url_shortener.arn
  handler          = "lambda.handler"
  runtime          = "python3.13"
  memory_size      = 2048
  timeout          = 5
  layers           = ["arn:aws:lambda:us-east-1:017000801446:layer:AWSLambdaPowertoolsPythonV3-python313-x86_64:18"]
  architectures    = ["arm64"]
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  lifecycle {
    ignore_changes = [filename]
  }
}
