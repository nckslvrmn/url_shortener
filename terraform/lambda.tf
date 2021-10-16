resource "aws_lambda_function" "url_shortener" {
  filename      = "${path.module}/placeholder.zip"
  function_name = "url_shortener"
  role          = aws_iam_role.url_shortener.arn
  handler       = "lambda.handler"
  runtime       = "python3.9"
  memory_size   = 2048
  timeout       = 5

  lifecycle {
    ignore_changes = [filename]
  }
}

resource "aws_lambda_permission" "allow_apig" {
  statement_id  = "AllowExecutionFromAPIG"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.url_shortener.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.url_shortener.execution_arn}/*/*/*"
}
