# ⚡ URL Shortener

> A blazing-fast, serverless URL shortening service built with AWS Lambda, DynamoDB, and Terraform. Transform long URLs into short, shareable links with automatic expiration and instant redirects.

[![License](https://img.shields.io/github/license/yourusername/url_shortener)](LICENSE)
[![AWS Lambda](https://img.shields.io/badge/AWS-Lambda-orange?logo=aws-lambda)](https://aws.amazon.com/lambda/)
[![Python](https://img.shields.io/badge/Python-3.x-blue?logo=python)](https://www.python.org/)
[![Terraform](https://img.shields.io/badge/Terraform-IaC-purple?logo=terraform)](https://www.terraform.io/)

## ✨ Features

- **🚀 Serverless Architecture** - Built on AWS Lambda for infinite scalability
- **⚡ Lightning Fast** - Sub-second URL shortening and redirects
- **🔒 Secure by Design** - HTTPS-only with custom domain support
- **⏰ Auto-Expiration** - URLs automatically expire after 30 days
- **🎲 Collision-Free** - Smart random ID generation with collision detection
- **🌐 Custom Domain** - Use your own domain for branded short links
- **💰 Cost-Effective** - Pay only for what you use with serverless pricing
- **🛠️ Infrastructure as Code** - Complete Terraform configuration included

## 🏗️ Architecture

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│   Browser   │────▶│ CloudFront   │────▶│  S3 Static  │
│             │     │              │     │   Website   │
└─────────────┘     └──────────────┘     └─────────────┘
       │                    │
       │                    │
       ▼                    ▼
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│ Route 53    │────▶│ API Gateway  │────▶│   Lambda    │
│             │     │              │     │  Function   │
└─────────────┘     └──────────────┘     └─────────────┘
                                                │
                                                ▼
                                         ┌─────────────┐
                                         │  DynamoDB   │
                                         │    Table    │
                                         └─────────────┘
```

## 🚀 Quick Start

### Prerequisites

- AWS Account with appropriate permissions
- Terraform installed (v1.0+)
- Python 3.9+ (for local development)
- AWS CLI configured
- A registered domain name
- ACM certificate for your domain

### Deployment

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/url_shortener.git
   cd url_shortener
   ```

2. **Package the Lambda function**
   ```bash

   zip -r lambda_function.zip lambda.py static/
   ```

3. **Configure Terraform variables**
   ```bash
   cd terraform

   # Create terraform.tfvars
   cat > terraform.tfvars << EOF
   hosted_zone_id = "YOUR_ROUTE53_ZONE_ID"
   domain_name    = "s.yourdomain.com"
   acm_arn        = "YOUR_ACM_CERTIFICATE_ARN"
   EOF
   ```

4. **Deploy infrastructure**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

5. **Access your URL shortener**

   Navigate to `https://s.yourdomain.com` to start shortening URLs!

## 📖 API Documentation

### Shorten URL

**Endpoint:** `POST /store`

**Request Body:**
```json
{
  "full_url": "https://example.com/very/long/url/that/needs/shortening"
}
```

**Response:**
```json
{
  "short_url_id": "AbCd3f"
}
```

**Example:**
```bash
curl -X POST https://s.yourdomain.com/store \
  -H "Content-Type: application/json" \
  -d '{"full_url": "https://github.com/yourusername/url_shortener"}'
```

### Redirect

**Endpoint:** `GET /{short_url_id}`

**Response:** `302 Redirect` to the original URL

**Example:**
```bash
curl -I https://s.yourdomain.com/AbCd3f
# HTTP/2 302
# location: https://github.com/yourusername/url_shortener
```

## 🛠️ Development

### Local Setup

1. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   pip install -r requirements-dev.txt  # For development tools
   ```

2. **Run tests**
   ```bash
   pytest tests/
   ```

3. **Local Lambda testing**
   ```bash
   # Using SAM CLI
   sam local start-api
   ```

### Project Structure

```
url_shortener/
├── lambda.py              # Main Lambda function
├── requirements.txt       # Python dependencies
├── static/
│   └── index.html        # Frontend UI
├── terraform/
│   ├── apig.tf           # API Gateway configuration
│   ├── apig_routes.tf    # API routes
│   ├── dynamo.tf         # DynamoDB table
│   ├── iam.tf            # IAM roles and policies
│   ├── lambda.tf         # Lambda function
│   ├── route53.tf        # DNS configuration
│   ├── s3.tf             # Static website hosting
│   └── variables.tf      # Terraform variables
└── tests/                # Unit tests
```

## ⚙️ Configuration

### Environment Variables

The Lambda function uses the following configuration:

- **AWS_REGION** - AWS region (default: `us-east-1`)
- **DYNAMODB_TABLE** - DynamoDB table name (default: `URLDB`)
- **URL_TTL_DAYS** - URL expiration in days (default: `30`)

### DynamoDB Schema

```
Table: URLDB
├── Primary Key: short_url_id (String)
├── Attributes:
│   ├── full_url (String)
│   ├── created_at (Number - Unix timestamp)
│   └── ttl (Number - Unix timestamp)
└── TTL Attribute: ttl
```

### Terraform Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `hosted_zone_id` | Route53 hosted zone ID | Yes |
| `domain_name` | Custom domain for short URLs | Yes |
| `acm_arn` | ACM certificate ARN | Yes |

## 📊 Monitoring & Logging

### CloudWatch Metrics

Monitor your URL shortener with these key metrics:

- **Lambda Invocations** - Total number of shortening/redirect requests
- **Lambda Errors** - Failed requests
- **Lambda Duration** - Response time performance
- **DynamoDB Read/Write Units** - Database throughput

### Logging

All Lambda logs are automatically sent to CloudWatch Logs:
```bash
aws logs tail /aws/lambda/url-shortener --follow
```

## 💰 Cost Estimation

Based on AWS pricing (us-east-1):

| Service | Free Tier | Cost After Free Tier |
|---------|-----------|---------------------|
| Lambda | 1M requests/month | $0.20 per 1M requests |
| DynamoDB | 25 GB storage | $0.25 per GB/month |
| API Gateway | 1M requests/month | $3.50 per 1M requests |
| Route53 | - | $0.50 per hosted zone |

**Estimated monthly cost for 100K requests:** ~$2-5

## 🔒 Security

- **HTTPS Only** - All traffic encrypted in transit
- **IAM Least Privilege** - Minimal permissions for Lambda
- **Input Validation** - URL format validation
- **DynamoDB Encryption** - Data encrypted at rest
- **API Throttling** - Rate limiting via API Gateway

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Write tests for new features
- Update documentation as needed
- Follow PEP 8 for Python code
- Use conventional commits

## 📈 Roadmap

- [ ] Analytics dashboard
- [ ] Custom short URL aliases
- [ ] QR code generation
- [ ] Click tracking
- [ ] API key authentication
- [ ] Bulk URL shortening
- [ ] URL preview feature
- [ ] Webhook support

## 🐛 Troubleshooting

### Common Issues

**Short URLs not working**
- Check Route53 DNS propagation
- Verify ACM certificate is validated
- Ensure API Gateway deployment is active

**Lambda timeouts**
- Increase Lambda memory/timeout
- Check DynamoDB throttling
- Review CloudWatch logs

**Terraform errors**
- Verify AWS credentials
- Check IAM permissions
- Ensure all variables are set

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [AWS Lambda Powertools](https://awslabs.github.io/aws-lambda-powertools-python/) for simplified Lambda development
- [Terraform AWS Modules](https://registry.terraform.io/browse/modules) for infrastructure patterns
- The serverless community for inspiration

---

<p align="center">
  Made with ❤️ and ☕ by developers, for developers
</p>

<p align="center">
  <a href="#-url-shortener">Back to top ⬆️</a>
</p>
