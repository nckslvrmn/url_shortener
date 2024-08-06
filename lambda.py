import random
import string
import time

import boto3

from aws_lambda_powertools.event_handler import APIGatewayRestResolver, Response
from aws_lambda_powertools.utilities.typing.lambda_context import LambdaContext


app = APIGatewayRestResolver()


@app.post("/store")
def store():
    short_url_id = "".join(random.choice(string.ascii_letters + string.digits) for _ in range(6))
    table = boto3.resource("dynamodb", region_name="us-east-1").Table("URLDB")
    try:
        table.put_item(
            Item={
                "short_url_id": short_url_id,
                "full_url": app.current_event.json_body["full_url"],
                "created_at": int(time.time()),
                "ttl": int(time.time()) + (86400 * 30),
            },
            ConditionExpression="attribute_not_exists(short_url_id)",
        )
        return {"short_url_id": short_url_id}
    except:
        return Response(status_code=500)


@app.get(".+")
def redirect():
    table = boto3.resource("dynamodb", region_name="us-east-1").Table("URLDB")
    record = table.get_item(Key={"short_url_id": app.current_event["path"].split("/")[-1]})

    if record["Item"].get("full_url"):
        return Response(status_code=302, headers={"Location": record["Item"].get("full_url")})
    else:
        return Response(status_code=404)


def handler(event: dict, context: LambdaContext) -> dict:
    return app.resolve(event, context)
