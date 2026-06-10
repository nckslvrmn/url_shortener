# URL Shortener

A little serverless URL shortener I run on AWS. You give it a long URL, it hands back a short ID, and `https://s.yourdomain.com/{id}` redirects you to the original. Links expire after 30 days.

[![License](https://img.shields.io/github/license/nckslvrmn/url_shortener)](LICENSE)
[![Python](https://img.shields.io/badge/Python-3.13-blue?logo=python)](https://www.python.org/)
[![Terraform](https://img.shields.io/badge/Terraform-IaC-purple?logo=terraform)](https://www.terraform.io/)

## How it works

The fun part: the hot paths don't touch Lambda at all.

```
GET  /             API Gateway -> S3            (static frontend)
GET  /{short_id}   API Gateway -> DynamoDB      (302 redirect, VTL mapped)
POST /store        API Gateway -> Lambda        (generate id + write)
```

Redirects go straight from API Gateway to DynamoDB via a VTL mapping template, so there's no cold start to wait on. That matters more than you'd think. A cold Lambda can take a couple seconds to respond, which is long enough for link unfurlers (Discord, Slack, etc.) to time out and skip the preview card. Going Lambda-less on the redirect path fixes that and keeps it fast and cheap.

Lambda only runs when you create a link, which is the one path that actually needs logic (random id + conditional write). Everything is REST API v1 because the direct DynamoDB and S3 integrations need VTL, and VTL is a v1-only feature.

## Stack

- **API Gateway** (REST v1) with direct DynamoDB and S3 integrations
- **Lambda** (Python 3.13, arm64) for `POST /store`, with Powertools via a layer
- **DynamoDB** (`URLDB`, on-demand, 30-day TTL)
- **S3** for the static frontend
- **Route53** alias to the custom domain

## Deploy

Everything is Terraform under `terraform/`, and it's set up to be consumed as a module. `terraform apply` is the whole deploy: it zips `lambda.py`, pushes the function code, and uploads `static/index.html` to S3. No separate build step.

```hcl
module "url_shortener" {
  source = "github.com/nckslvrmn/url_shortener//terraform"

  hosted_zone_id = "YOUR_ROUTE53_ZONE_ID"
  domain_name    = "s.yourdomain.com"
  acm_arn        = "arn:aws:acm:..." # regional cert in the API's region
}
```

Or just run it directly:

```bash
cd terraform
terraform init
terraform apply
```

## API

**Create a link:**

```bash
curl -X POST https://s.yourdomain.com/store \
  -H "Content-Type: application/json" \
  -d '{"full_url": "https://example.com/some/long/path"}'
# { "short_url_id": "AbCd3f" }
```

`full_url` has to be a valid URL or you get a `422`.

**Use it:** `GET /{short_url_id}` redirects (`302`), or `404` if the id is unknown or expired.

## Notes

- `requirements.txt` is just for local dev. At runtime Powertools comes from the layer and boto3 comes from the Lambda runtime.
- Logs are structured JSON in CloudWatch: `aws logs tail /aws/lambda/url_shortener --follow`

## License

MIT, see [LICENSE](LICENSE).
