### Root Route
resource "aws_api_gateway_method" "root" {
  rest_api_id   = aws_api_gateway_rest_api.url_shortener.id
  resource_id   = aws_api_gateway_rest_api.url_shortener.root_resource_id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "root" {
  rest_api_id             = aws_api_gateway_rest_api.url_shortener.id
  resource_id             = aws_api_gateway_rest_api.url_shortener.root_resource_id
  http_method             = aws_api_gateway_method.root.http_method
  integration_http_method = "GET"
  type                    = "AWS"
  credentials             = aws_iam_role.apigateway.arn
  uri                     = "arn:aws:apigateway:us-east-1:s3:path/${var.domain_name}/index.html"
}

resource "aws_api_gateway_method_response" "root_response_200" {
  rest_api_id = aws_api_gateway_rest_api.url_shortener.id
  resource_id = aws_api_gateway_rest_api.url_shortener.root_resource_id
  http_method = aws_api_gateway_method.root.http_method
  status_code = "200"

  response_models = {
    "text/html" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "root_response" {
  rest_api_id = aws_api_gateway_rest_api.url_shortener.id
  resource_id = aws_api_gateway_rest_api.url_shortener.root_resource_id
  http_method = aws_api_gateway_method.root.http_method
  status_code = aws_api_gateway_method_response.root_response_200.status_code
}


### Store URL Routes
resource "aws_api_gateway_resource" "store" {
  path_part   = "store"
  parent_id   = aws_api_gateway_rest_api.url_shortener.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.url_shortener.id
}

resource "aws_api_gateway_method" "store" {
  rest_api_id   = aws_api_gateway_rest_api.url_shortener.id
  resource_id   = aws_api_gateway_resource.store.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "store" {
  rest_api_id             = aws_api_gateway_rest_api.url_shortener.id
  resource_id             = aws_api_gateway_resource.store.id
  http_method             = aws_api_gateway_method.store.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.url_shortener.invoke_arn
}


### Redirect URL Route
resource "aws_api_gateway_resource" "redirect" {
  path_part   = "{short_url_id}"
  parent_id   = aws_api_gateway_rest_api.url_shortener.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.url_shortener.id
}

resource "aws_api_gateway_method" "redirect" {
  rest_api_id   = aws_api_gateway_rest_api.url_shortener.id
  resource_id   = aws_api_gateway_resource.redirect.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "redirect" {
  rest_api_id             = aws_api_gateway_rest_api.url_shortener.id
  resource_id             = aws_api_gateway_resource.redirect.id
  http_method             = aws_api_gateway_method.redirect.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.url_shortener.invoke_arn
}
