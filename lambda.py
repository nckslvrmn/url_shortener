import random
import re
import string
import time
import os

import boto3
from botocore.exceptions import ClientError
from pydantic import BaseModel, HttpUrl, field_validator

from aws_lambda_powertools import Logger
from aws_lambda_powertools.event_handler import APIGatewayHttpResolver, Response
from aws_lambda_powertools.event_handler.exceptions import (
    BadRequestError,
    InternalServerError,
    NotFoundError,
)
from aws_lambda_powertools.utilities.typing import LambdaContext


logger = Logger()
app = APIGatewayHttpResolver(enable_validation=True)


class StoreRequest(BaseModel):
    full_url: HttpUrl
    permanent: bool = False
    custom_id: str | None = None

    @field_validator("custom_id")
    @classmethod
    def validate_custom_id(cls, v: str | None) -> str | None:
        if v is not None:
            v = v.strip()
            if not v:
                return None
            if not re.match(r"^[a-zA-Z0-9_-]{1,50}$", v):
                raise ValueError(
                    "Custom ID must be 1–50 alphanumeric characters, hyphens, or underscores"
                )
        return v


@app.get("/")
def index():
    html_path = os.path.join(os.path.dirname(__file__), "static", "index.html")
    try:
        with open(html_path, "r") as f:
            html_content = f.read()
    except FileNotFoundError:
        raise InternalServerError("HTML file not found in deployment package")

    return Response(status_code=200, content_type="text/html", body=html_content)


@app.post("/store")
def store(body: StoreRequest):
    short_url_id = body.custom_id or "".join(
        random.choice(string.ascii_letters + string.digits) for _ in range(6)
    )
    table = boto3.resource("dynamodb", region_name="us-east-1").Table("URLDB")
    item: dict = {
        "short_url_id": short_url_id,
        "full_url": str(body.full_url),
        "created_at": int(time.time()),
    }
    if not body.permanent:
        item["ttl"] = int(time.time()) + (86400 * 30)
    try:
        table.put_item(
            Item=item,
            ConditionExpression="attribute_not_exists(short_url_id)",
        )
    except ClientError as e:
        if e.response["Error"]["Code"] == "ConditionalCheckFailedException":
            raise BadRequestError(f"Short URL '{short_url_id}' is already taken")
        logger.exception("Failed to store URL", extra={"short_url_id": short_url_id})
        raise InternalServerError("Failed to store URL")

    logger.info("Short URL created", extra={"short_url_id": short_url_id})
    return {"short_url_id": short_url_id}


@app.get("/<short_url_id>")
def redirect(short_url_id: str):
    table = boto3.resource("dynamodb", region_name="us-east-1").Table("URLDB")
    try:
        record = table.get_item(Key={"short_url_id": short_url_id})
    except ClientError:
        logger.exception("DynamoDB error during redirect", extra={"short_url_id": short_url_id})
        raise InternalServerError("Failed to retrieve URL")

    if "Item" not in record or not record["Item"].get("full_url"):
        raise NotFoundError("Short URL not found")

    return Response(status_code=302, headers={"Location": record["Item"]["full_url"]})


@logger.inject_lambda_context
def handler(event: dict, context: LambdaContext) -> dict:
    return app.resolve(event, context)
