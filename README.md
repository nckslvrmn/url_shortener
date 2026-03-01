# URL Shortener

Serverless URL shortening service built on AWS Lambda, API Gateway, DynamoDB, and Terraform. Short URLs expire automatically after 30 days.

[![License](https://img.shields.io/github/license/nckslvrmn/url_shortener)](LICENSE)
[![AWS Lambda](https://img.shields.io/badge/AWS-Lambda-orange?logo=aws-lambda)](https://aws.amazon.com/lambda/)
[![Python](https://img.shields.io/badge/Python-3.13-blue?logo=python)](https://www.python.org/)
[![Terraform](https://img.shields.io/badge/Terraform-IaC-purple?logo=terraform)](https://www.terraform.io/)

## Architecture

```
Browser → Route53 (A alias) → API Gateway HTTP API → Lambda (Python 3.13, arm64) → DynamoDB
```

- **API Gateway HTTP API v2** — routes `GET /`, `POST /store`, `GET /{short_url_id}`
- **Lambda** — Python 3.13, arm64, 2048 MB, 5s timeout; serves the frontend HTML directly from the deployment package
- **DynamoDB** — `URLDB` table, on-demand billing, TTL enabled (30-day expiry)
- **Route53** — A alias record pointing to the API Gateway custom domain
- **AWS Lambda Powertools** — delivered via Lambda Layer (not bundled in the zip)

## Deployment

### Prerequisites

- AWS account with appropriate permissions
- Terraform v1.0+
- AWS CLI configured
- A registered domain with a Route53 hosted zone
- ACM certificate for the domain (us-east-1)

### Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/nckslvrmn/url_shortener.git
   cd url_shortener
   ```

2. **Configure Terraform variables**
   ```bash
   cd terraform
   cat > terraform.tfvars << EOF
   hosted_zone_id = "YOUR_ROUTE53_ZONE_ID"
   domain_name    = "s.yourdomain.com"
   acm_arn        = "arn:aws:acm:us-east-1:..."
   EOF
   ```

3. **Deploy**
   ```bash
   terraform init
   terraform apply
   ```

   Terraform zips `lambda.py` and `static/index.html` automatically via the `archive_file` data source — no manual packaging needed.

## API

### `POST /store`

Shorten a URL.

**Request**
```bash
curl -X POST https://s.yourdomain.com/store \
  -H "Content-Type: application/json" \
  -d '{"full_url": "https://example.com/some/long/path"}'
```

**Response**
```json
{ "short_url_id": "AbCd3f" }
```

The `full_url` field must be a valid URL — invalid input returns `422`.

### `GET /{short_url_id}`

Redirects to the original URL (`302`). Returns `404` if the ID does not exist or has expired.

## Infrastructure

All infrastructure lives in `terraform/`:

| File | Purpose |
|------|---------|
| `apig_http.tf` | API Gateway HTTP API, routes, custom domain, stage |
| `lambda.tf` | Lambda function, deployment package, Powertools layer |
| `dynamo.tf` | DynamoDB table with TTL |
| `route53.tf` | A alias record for the custom domain |
| `iam.tf` | Lambda execution role, DynamoDB least-privilege policy |
| `variables.tf` | `hosted_zone_id`, `domain_name`, `acm_arn` |

### Terraform Variables

| Variable | Description |
|----------|-------------|
| `hosted_zone_id` | Route53 hosted zone ID |
| `domain_name` | Custom domain (e.g. `s.yourdomain.com`) |
| `acm_arn` | ACM certificate ARN (must be in `us-east-1`) |

## DynamoDB Schema

Table: `URLDB`

| Attribute | Type | Description |
|-----------|------|-------------|
| `short_url_id` | String (PK) | 6-character random alphanumeric ID |
| `full_url` | String | Original URL |
| `created_at` | Number | Unix timestamp of creation |
| `ttl` | Number | Unix timestamp of expiry (30 days out) |

## Local Development

Python dependencies are only needed for local development — Lambda uses the Powertools layer at runtime.

```bash
pip install -r requirements.txt
```

## Monitoring

Lambda logs are structured JSON via AWS Lambda Powertools Logger and are sent to CloudWatch Logs automatically.

```bash
aws logs tail /aws/lambda/url_shortener --follow
```

## License

MIT — see [LICENSE](LICENSE).
