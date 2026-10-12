import json
import os
from datetime import UTC, datetime

import boto3

TABLE_NAME = os.environ["TABLE_NAME"]
COUNTER_ID = "resume"

ALLOWED_SOURCES = {
    "linkedin",
    "github",
}

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(TABLE_NAME)


def handler(event, context):
    query = event.get("queryStringParameters") or {}

    requested_source = query.get("ref", "").lower()
    source = (
        requested_source
        if requested_source in ALLOWED_SOURCES
        else "direct"
    )

    today = datetime.now(UTC).strftime("%Y_%m_%d")

    day_attribute = f"day_{today}"
    source_attribute = f"source_{source}"

    response = table.update_item(
        Key={"id": COUNTER_ID},
        UpdateExpression="ADD visits :increment, #day :increment, #source :increment",
        ExpressionAttributeNames={
            "#day": day_attribute,
            "#source": source_attribute,
        },
        ExpressionAttributeValues={
            ":increment": 1,
        },
        ReturnValues="UPDATED_NEW",
    )

    visits = int(response["Attributes"]["visits"])

    return {
        "statusCode": 200,
        "body": json.dumps({"visits": visits}),
    }
