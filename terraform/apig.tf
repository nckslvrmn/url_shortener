resource "aws_api_gateway_rest_api" "url_shortener" {
  name = "url_shortener"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# ---------------------------------------------------------------------------
# GET /  ->  static index.html served directly from S3 (no Lambda)
# ---------------------------------------------------------------------------
resource "aws_api_gateway_method" "root_get" {
  rest_api_id   = aws_api_gateway_rest_api.url_shortener.id
  resource_id   = aws_api_gateway_rest_api.url_shortener.root_resource_id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "root_s3" {
  rest_api_id             = aws_api_gateway_rest_api.url_shortener.id
  resource_id             = aws_api_gateway_rest_api.url_shortener.root_resource_id
  http_method             = aws_api_gateway_method.root_get.http_method
  type                    = "AWS"
  integration_http_method = "GET"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.region}:s3:path/${aws_s3_bucket.static.bucket}/index.html"
  credentials             = aws_iam_role.apig.arn
}

resource "aws_api_gateway_method_response" "root_200" {
  rest_api_id = aws_api_gateway_rest_api.url_shortener.id
  resource_id = aws_api_gateway_rest_api.url_shortener.root_resource_id
  http_method = aws_api_gateway_method.root_get.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Content-Type" = true
  }
}

resource "aws_api_gateway_integration_response" "root_200" {
  rest_api_id = aws_api_gateway_rest_api.url_shortener.id
  resource_id = aws_api_gateway_rest_api.url_shortener.root_resource_id
  http_method = aws_api_gateway_method.root_get.http_method
  status_code = aws_api_gateway_method_response.root_200.status_code

  response_parameters = {
    "method.response.header.Content-Type" = "integration.response.header.Content-Type"
  }

  depends_on = [aws_api_gateway_integration.root_s3]
}

# ---------------------------------------------------------------------------
# POST /store  ->  Lambda (random id generation + conditional write)
# ---------------------------------------------------------------------------
resource "aws_api_gateway_resource" "store" {
  rest_api_id = aws_api_gateway_rest_api.url_shortener.id
  parent_id   = aws_api_gateway_rest_api.url_shortener.root_resource_id
  path_part   = "store"
}

resource "aws_api_gateway_method" "store_post" {
  rest_api_id   = aws_api_gateway_rest_api.url_shortener.id
  resource_id   = aws_api_gateway_resource.store.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "store_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.url_shortener.id
  resource_id             = aws_api_gateway_resource.store.id
  http_method             = aws_api_gateway_method.store_post.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.url_shortener.invoke_arn
}

# ---------------------------------------------------------------------------
# GET /{short_url_id}  ->  DynamoDB GetItem -> 302 redirect (no Lambda)
# ---------------------------------------------------------------------------
resource "aws_api_gateway_resource" "redirect" {
  rest_api_id = aws_api_gateway_rest_api.url_shortener.id
  parent_id   = aws_api_gateway_rest_api.url_shortener.root_resource_id
  path_part   = "{short_url_id}"
}

resource "aws_api_gateway_method" "redirect_get" {
  rest_api_id   = aws_api_gateway_rest_api.url_shortener.id
  resource_id   = aws_api_gateway_resource.redirect.id
  http_method   = "GET"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.short_url_id" = true
  }
}

resource "aws_api_gateway_integration" "redirect_dynamo" {
  rest_api_id             = aws_api_gateway_rest_api.url_shortener.id
  resource_id             = aws_api_gateway_resource.redirect.id
  http_method             = aws_api_gateway_method.redirect_get.http_method
  type                    = "AWS"
  integration_http_method = "POST"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.region}:dynamodb:action/GetItem"
  credentials             = aws_iam_role.apig.arn
  passthrough_behavior    = "WHEN_NO_TEMPLATES"

  request_templates = {
    "application/json" = <<EOF
{
  "TableName": "${aws_dynamodb_table.url_shortener.name}",
  "Key": {
    "short_url_id": {
      "S": "$util.escapeJavaScript($input.params('short_url_id'))"
    }
  }
}
EOF
  }
}

resource "aws_api_gateway_method_response" "redirect_302" {
  rest_api_id = aws_api_gateway_rest_api.url_shortener.id
  resource_id = aws_api_gateway_resource.redirect.id
  http_method = aws_api_gateway_method.redirect_get.http_method
  status_code = "302"

  response_parameters = {
    "method.response.header.Location" = true
  }
}

resource "aws_api_gateway_method_response" "redirect_404" {
  rest_api_id = aws_api_gateway_rest_api.url_shortener.id
  resource_id = aws_api_gateway_resource.redirect.id
  http_method = aws_api_gateway_method.redirect_get.http_method
  status_code = "404"
}

# DynamoDB GetItem always returns 200; we branch on whether Item exists and
# rewrite the status/headers with $context.responseOverride.
resource "aws_api_gateway_integration_response" "redirect" {
  rest_api_id = aws_api_gateway_rest_api.url_shortener.id
  resource_id = aws_api_gateway_resource.redirect.id
  http_method = aws_api_gateway_method.redirect_get.http_method
  status_code = aws_api_gateway_method_response.redirect_302.status_code

  response_templates = {
    "application/json" = <<EOF
#set($item = $input.path('$').Item)
#if($item && $item.full_url && $item.full_url.S && $item.full_url.S != "")
#set($context.responseOverride.header.Location = $item.full_url.S)
#set($context.responseOverride.status = 302)
#else
#set($context.responseOverride.status = 404)
#end
EOF
  }

  depends_on = [aws_api_gateway_integration.redirect_dynamo]
}

# ---------------------------------------------------------------------------
# Deployment + stage
# ---------------------------------------------------------------------------
resource "aws_api_gateway_deployment" "url_shortener" {
  rest_api_id = aws_api_gateway_rest_api.url_shortener.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_method.root_get.id,
      aws_api_gateway_integration.root_s3.id,
      aws_api_gateway_integration_response.root_200.id,
      aws_api_gateway_resource.store.id,
      aws_api_gateway_method.store_post.id,
      aws_api_gateway_integration.store_lambda.id,
      aws_api_gateway_resource.redirect.id,
      aws_api_gateway_method.redirect_get.id,
      aws_api_gateway_integration.redirect_dynamo.id,
      aws_api_gateway_integration_response.redirect.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "main" {
  rest_api_id   = aws_api_gateway_rest_api.url_shortener.id
  deployment_id = aws_api_gateway_deployment.url_shortener.id
  stage_name    = "prod"
}

# ---------------------------------------------------------------------------
# Custom domain
# ---------------------------------------------------------------------------
resource "aws_api_gateway_domain_name" "url_shortener" {
  domain_name              = var.domain_name
  regional_certificate_arn = var.acm_arn
  security_policy          = "TLS_1_2"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_base_path_mapping" "url_shortener" {
  api_id      = aws_api_gateway_rest_api.url_shortener.id
  stage_name  = aws_api_gateway_stage.main.stage_name
  domain_name = aws_api_gateway_domain_name.url_shortener.domain_name
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.url_shortener.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.url_shortener.execution_arn}/*/*"
}
