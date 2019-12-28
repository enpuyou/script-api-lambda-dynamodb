"""Lambda function to handle POST and GET"""
import json
from decimal import Decimal
import uuid
import boto3
# import datetime


def lambda_handler(event, context):
    """Handles incoming request"""
    if event['httpMethod'] == "POST":
        return lambda_post_handler(event, context)
    elif event['httpMethod'] == "GET":
        return lambda_get_handler(event, context)


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


def lambda_post_handler(event, context):
    """Sent data from API Gateway to the table"""
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('upload-table-sh')
    data = json.loads(event['body'])
    data = convert_empty_values(data)
    data['ID'] = str(uuid.uuid4())

    response = table.put_item(
        Item=data
    )

    # print("PutItem not succeeded :")
    # else:
    #     print("PutItem succeeded: ")
    print(json.dumps(response, indent=4))
    response_body = response['ResponseMetadata']
    format_response = {
        "isBase64Encoded": False,
        "statusCode": response_body['HTTPStatusCode'],
        "headers": response_body['HTTPHeaders'],
        "body": event['body']
    }

    return format_response


class CustomJsonEncoder(json.JSONEncoder):
    """JSONEncoder for get item"""
    def default(self, obj):
        """Convert Decimal to float"""
        if isinstance(obj, Decimal):
            return float(obj)
        return super(CustomJsonEncoder, self).default(obj)


def lambda_get_handler(event, context):
    dynamodb = boto3.resource("dynamodb", region_name='us-east-2', endpoint_url="https://dynamodb.us-east-2.amazonaws.com")
    table = dynamodb.Table('upload-table-sh')
    assignment = "java-assignment-solution-100-01"
    response = table.get_item(
        Key={
            'ID': "4dbc7496-669d-4e2b-9572-f2a5b68d914c",

        }
    )
    item = response['Item']
    item = json.dumps(item, cls=CustomJsonEncoder)
    response_body = response['ResponseMetadata']
    format_response = {
        "isBase64Encoded": False,
        "statusCode": response_body['HTTPStatusCode'],
        "headers": response_body['HTTPHeaders'],
        "body": item
    }
    print("GetItem succeeded:")

    return format_response
