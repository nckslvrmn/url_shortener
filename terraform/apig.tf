resource "aws_api_gateway_rest_api" "url_shortener" {
  name = "url_shortener"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.url_shortener.id

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_method_response.root_response_200,
  ]
}

resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.url_shortener.id
  stage_name    = "main"

  depends_on = [
    aws_api_gateway_method_response.root_response_200,
  ]
}

resource "aws_apigatewayv2_domain_name" "url_shortener" {
  domain_name = var.domain_name

  domain_name_configuration {
    certificate_arn = var.acm_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

resource "aws_apigatewayv2_api_mapping" "url_shortener" {
  api_id      = aws_api_gateway_rest_api.url_shortener.id
  domain_name = aws_apigatewayv2_domain_name.url_shortener.id
  stage       = aws_api_gateway_stage.main.stage_name
}

