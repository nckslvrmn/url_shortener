import random
import string
import time
from typing import Annotated, Optional

import boto3
from botocore.exceptions import ClientError
from pydantic import BaseModel, Field, HttpUrl, field_validator

from aws_lambda_powertools import Logger
from aws_lambda_powertools.event_handler import APIGatewayRestResolver
from aws_lambda_powertools.event_handler.exceptions import (
    BadRequestError,
    InternalServerError,
    ServiceError,
)
from aws_lambda_powertools.utilities.typing import LambdaContext


logger = Logger()
app = APIGatewayRestResolver(enable_validation=True)

# Path parts that would shadow (or be shadowed by) other API Gateway routes and
# therefore can't be used as custom short ids.
RESERVED_IDS = {"store", "index.html"}


class StoreRequest(BaseModel):
    full_url: HttpUrl
    permanent: bool = False
    custom_id: Optional[Annotated[str, Field(pattern=r"^[A-Za-z0-9_-]{1,64}$")]] = None

    @field_validator("full_url", mode="before")
    @classmethod
    def default_scheme(cls, v):
        # Accept bare domains (e.g. "google.com") by assuming https://
        if isinstance(v, str) and "://" not in v:
            return f"https://{v}"
        return v


@app.post("/store")
def store(body: StoreRequest):
    if body.custom_id:
        if body.custom_id.lower() in RESERVED_IDS:
            raise BadRequestError("That custom short name is reserved")
        short_url_id = body.custom_id
    else:
        short_url_id = "".join(
            random.choice(string.ascii_letters + string.digits) for _ in range(6)
        )

    now = int(time.time())
    item = {
        "short_url_id": short_url_id,
        "full_url": str(body.full_url),
        "created_at": now,
    }
    if not body.permanent:
        item["ttl"] = now + (86400 * 30)

    table = boto3.resource("dynamodb", region_name="us-east-1").Table("URLDB")
    try:
        table.put_item(
            Item=item,
            ConditionExpression="attribute_not_exists(short_url_id)",
        )
    except ClientError as e:
        if (
            e.response["Error"]["Code"] == "ConditionalCheckFailedException"
            and body.custom_id
        ):
            raise ServiceError(409, "That custom short name is already taken")
        logger.exception("Failed to store URL", extra={"short_url_id": short_url_id})
        raise InternalServerError("Failed to store URL")

    logger.info(
        "Short URL created",
        extra={"short_url_id": short_url_id, "permanent": body.permanent},
    )
    return {"short_url_id": short_url_id}


@logger.inject_lambda_context
def handler(event: dict, context: LambdaContext) -> dict:
    return app.resolve(event, context)
