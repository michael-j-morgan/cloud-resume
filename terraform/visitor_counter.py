import json
import os

import boto3

TABLE_NAME = os.environ["TABLE_NAME"]
COUNTER_ID = "resume"

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(TABLE_NAME)


def handler(event, context):
    response = table.update_item(
        Key={"id": COUNTER_ID},
        UpdateExpression="ADD visits :increment",
        ExpressionAttributeValues={":increment": 1},
        ReturnValues="UPDATED_NEW",
    )

    visits = int(response["Attributes"]["visits"])

    return {
        "statusCode": 200,
        "body": json.dumps({"visits": visits}),
    }
