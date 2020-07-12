"""Lambda function to handle POST and GET"""
import json
from decimal import Decimal
import boto3
import uuid
from boto3.dynamodb.conditions import Key, Attr

# import datetime

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("upload-table-sh")


def lambda_handler(event, context):
    """Handles incoming request"""
    if event["httpMethod"] == "POST":
        response = post_handler(event, context)
        body = event["body"]
    elif event["httpMethod"] == "GET":
        response = get_handler(event, context)
        # aws require content in body be string type
        body = json.dumps(response["Item"], cls=CustomJsonEncoder)
    # reformat for lambda proxy response
    format_response = {
        "isBase64Encoded": False,
        "statusCode": response["HTTPStatusCode"],
        "headers": response["HTTPHeaders"],
        "body": body,
    }
    return format_response


def post_handler(event, context):
    """Sent data from API Gateway to the table"""
    data = json.loads(event["body"])
    data = convert_empty_values(data)
    data["uuidID"] = str(uuid.uuid4())
    response = table.put_item(Item=data)
    return response["ResponseMetadata"]


def get_handler(event, context):
    key = []
    value = []
    # Items: [assignment, passBuild]
    for k, v in event["queryStringParameters"].items():
        # parameter key
        key.append(k)
        # parameter name
        value.append(v)
    if value[1] is not True:
        response = table.query(KeyConditionExpression=Key(key[0]).eq(value[0]))
    else:
        response = table.query(
            KeyConditionExpression=Key(key).eq(value),
            FilterExpression=Attr('report').contains(
                '"numberOfFailures" : { "N" : "0" }')
        )
    # Add item fetched to the return statement
    response["ResponseMetadata"]["Item"] = response["Items"]
    return response["ResponseMetadata"]


def convert_empty_values(raw):
    """Convert empty values to Null for Nosql"""
    if isinstance(raw, dict):
        for k, v in raw.items():
            raw[k] = convert_empty_values(v)
    elif isinstance(raw, list):
        for i in range(len(raw)):
            raw[i] = convert_empty_values(raw[i])
    elif raw == "":
        raw = None

    return raw


class CustomJsonEncoder(json.JSONEncoder):
    """JSONEncoder for get item"""

    def default(self, obj):
        """Convert Decimal to float"""
        if isinstance(obj, Decimal):
            return float(obj)
        return super(CustomJsonEncoder, self).default(obj)
