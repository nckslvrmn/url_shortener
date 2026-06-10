import random
import string
import time

import boto3
from botocore.exceptions import ClientError
from pydantic import BaseModel, HttpUrl

from aws_lambda_powertools import Logger
from aws_lambda_powertools.event_handler import APIGatewayRestResolver
from aws_lambda_powertools.event_handler.exceptions import InternalServerError
from aws_lambda_powertools.utilities.typing import LambdaContext


logger = Logger()
app = APIGatewayRestResolver(enable_validation=True)


class StoreRequest(BaseModel):
    full_url: HttpUrl


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


@logger.inject_lambda_context
def handler(event: dict, context: LambdaContext) -> dict:
    return app.resolve(event, context)
