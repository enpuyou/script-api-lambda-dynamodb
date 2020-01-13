# script-api-lambda-dynamodb

[![Build Status](https://travis-ci.com/enpuyou/script-api-lambda-dynamodb.svg?branch=master)](https://travis-ci.com/enpuyou/script-api-lambda-dynamodb)

A script for automating deployment of `api-lambda-dynamodb` that will

- Create an `IAM Role` with policies that allows the usage of `Lambda`,
  `DynamoDB`, `APIGateway`, and `CloudWatchLogs`

- Create and deploy an API with two methods: POST(API Key required) and
  GET(`IAM-USER` and API Key required)

- Create an API Key and Usage Plan for the HTTP Request

- Create an `DynamoDB` table with a primary partition key named `assignment`
  (String) and a primary sort key automated generated named `uuidID`(String)

- Create a `Lambda` function that handles invocation from `APIGateway` to
  store and retrieve/query data from the previous `DynamoDB` table.

- Test invoke the API to get a status code

- Provide configurable names of IAM role, `Lambda` function, `DynamoDB` table,
  API, and etc. at the top of the script file

## Instruction

### Make AWS account

After successfully making the account, go to

```
My Security Credentials > Access keys > Create New Access Key
```

![AWS Secret Credential Page](aws_credential_page.png)

This will generate and download a `csv` file containing the `Access Key ID`
and `Secret Access Key`, which later will be put into the `AWS-CLI` configuration.
Save them as environment variables using `AWS_ACCESS_KEY_ID` and
`AWS_SECRET_ACCESS_KEY`, like this:

```bash
export AWS_ACCESS_KEY_ID=<Your Access Key ID>
export AWS_SECRET_ACCESS_KEY=<Your Secret Access Key>
```

These will be used for authorizing GET request.

### Install AWS-CLI

```
pip install awscli
```

### Configure AWS-CLI

Type in the following command to fill in four configurations

```bash
aws configure
```

```
AWS Access Key ID [********************]:
AWS Secret Access Key [*******************]:
Default region name [us-east-2]:
Default output format [json]:
```

### Run Script

To run script within the current shell, type in:

```bash
source ./api-lambda-dynamodb.sh
```

### GET Request

Install `requests` library using pip:

```bash
pip install requests
```

To run the program and send a GET request:

```bash
python auth_get_request.py
```

## Other

[lambda_get_post_handler.py](https://github.com/enpuyou/script-api-lambda-dynamodb/blob/master/lambda_get_post_handler.py)
contains the code that will be in the Lambda function.

[auth_get_request](https://github.com/enpuyou/script-api-lambda-dynamodb/blob/master/auth_get_request.py)
contains the code that will sign and make a GET request.

[role-trust-policy.json](https://github.com/enpuyou/script-api-lambda-dynamodb/blob/master/role-trust-policy.json)
contains the JSON template of the role trust policy that allows the use of Lambda.

[script.md](https://github.com/enpuyou/script-api-lambda-dynamodb/blob/master/script.md)
shows each command with its expected output.

## Expected Output

```bash
script-api-lambda-dynamodb git:(master) source ./api-lambda-dynamodb.sh

{
    "FunctionName": "upload-test-sh",
    "FunctionArn": "arn:aws:lambda:us-east-2:359684827196:function:upload-test-sh",
    "Runtime": "python3.7",
    "Role": "arn:aws:iam::359684827196:role/upload-cli-sh",
    "Handler": "lambda_get_post_handler.lambda_handler",
    "CodeSize": 1148,
    "Description": "",
    "Timeout": 3,
    "MemorySize": 128,
    "LastModified": "2019-12-28T09:50:29.216+0000",
    "CodeSha256": "HMlA6iC1Ywg0VQPYYkZFmvkoMzQFx7Xz5CzDnHrvv0M=",
    "Version": "$LATEST",
    "TracingConfig": {
        "Mode": "PassThrough"
    },
    "RevisionId": "3b82f5d1-ca64-4f43-8a4c-c5c50e40fdaf",
    "State": "Active",
    "LastUpdateStatus": "Successful"
}
{
    "httpMethod": "POST",
    "authorizationType": "NONE",
    "apiKeyRequired": true
}
{
    "type": "AWS_PROXY",
    "httpMethod": "POST",
    "uri": "arn:aws:apigateway:us-east-2:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-2:359684827196:function:upload-test-sh/invocations",
    "passthroughBehavior": "WHEN_NO_MATCH",
    "timeoutInMillis": 29000,
    "cacheNamespace": "mdrhnv",
    "cacheKeyParameters": []
}
{
    "httpMethod": "GET",
    "authorizationType": "AWS_IAM",
    "apiKeyRequired": true
}
{
    "type": "AWS_PROXY",
    "httpMethod": "POST",
    "uri": "arn:aws:apigateway:us-east-2:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-2:359684827196:function:upload-test-sh/invocations",
    "passthroughBehavior": "WHEN_NO_MATCH",
    "timeoutInMillis": 29000,
    "cacheNamespace": "mdrhnv",
    "cacheKeyParameters": []
}
{
    "id": "tmalkq",
    "createdDate": 1577526636
}
{
    "Statement": "{\"Sid\":\"1\",\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"apigateway.amazonaws.com\"},\"Action\":\"lambda:InvokeFunction\",\"Resource\":\"arn:aws:lambda:us-east-2:359684827196:function:upload-test-sh\",\"Condition\":{\"ArnLike\":{\"AWS:SourceArn\":\"arn:aws:execute-api:us-east-2:359684827196:0lc46btkaf/*/POST/cli-test-sh\"}}}"
}
{
    "Statement": "{\"Sid\":\"2\",\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"apigateway.amazonaws.com\"},\"Action\":\"lambda:InvokeFunction\",\"Resource\":\"arn:aws:lambda:us-east-2:359684827196:function:upload-test-sh\",\"Condition\":{\"ArnLike\":{\"AWS:SourceArn\":\"arn:aws:execute-api:us-east-2:359684827196:0lc46btkaf/*/GET/cli-test-sh\"}}}"
}
{
    "id": "k8waegk7yg",
    "type": "API_KEY",
    "name": "upload-API-key"
}
{
    "TableDescription": {
        "AttributeDefinitions": [
            {
                "AttributeName": "assignment",
                "AttributeType": "S"
            }
        ],
        "TableName": "upload-table-sh",
        "KeySchema": [
            {
                "AttributeName": "assignment",
                "KeyType": "HASH"
            }
        ],
        "TableStatus": "CREATING",
        "CreationDateTime": 1577526640.867,
        "ProvisionedThroughput": {
            "NumberOfDecreasesToday": 0,
            "ReadCapacityUnits": 5,
            "WriteCapacityUnits": 5
        },
        "TableSizeBytes": 0,
        "ItemCount": 0,
        "TableArn": "arn:aws:dynamodb:us-east-2:359684827196:table/upload-table-sh",
        "TableId": "05a06acd-4f29-4148-9f57-c54db52f0991"
    }
}
200
```
