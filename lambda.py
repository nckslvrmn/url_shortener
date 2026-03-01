import random
import string
import time
import os

import boto3
from botocore.exceptions import ClientError
from pydantic import BaseModel, HttpUrl

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
    short_url_id = "".join(
        random.choice(string.ascii_letters + string.digits) for _ in range(6)
    )
    table = boto3.resource("dynamodb", region_name="us-east-1").Table("URLDB")
    try:
        table.put_item(
            Item={
                "short_url_id": short_url_id,
                "full_url": str(body.full_url),
                "created_at": int(time.time()),
                "ttl": int(time.time()) + (86400 * 30),
            },
            ConditionExpression="attribute_not_exists(short_url_id)",
        )
    except ClientError:
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
