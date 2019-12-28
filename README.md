# script-api-lambda-dynamodb

[![Build Status](https://travis-ci.com/enpuyou/script-api-lambda-dynamodb.svg?branch=master)](https://travis-ci.com/enpuyou/script-api-lambda-dynamodb)

A script for automating deployment of api-lambda-dynamodb

## Instruction

### Make AWS account

After successfully making the account, go to

```
My Security Credentials > Access keys > Create New Access Key
```

This will generate and download a `csv` file containing the
`Access Key ID` and `Secret Access Key`, which later will be put
in the AWS-CLI configure

![AWS Secret Credential Page](aws_credential_page.png)

### Install AWS-CLI

```
pip install awscli
```

### Configure AWS-CLI

Type in the following command to fill in four configurations

```
aws configure
```

```
AWS Access Key ID [********************]:
AWS Secret Access Key [*******************]:
Default region name [us-east-2]:
Default output format [json]:
```

### Run Script

To run script within the existing shell, type in:

```
source ./script.sh
```

This will

- Create an `IAM Role` with policies that allow the usage of `Lambda`,
  `DynamoDB`, `APIGateway`, and `CloudWatchLogs`

- Create and deploy an API with two methods: POST and GET

- Create an API Key and Usage Plan for the HTTP Request

- Create an DynamoDB table with an automated generated primary key named `assignment`

- Create a `Lambda` function to handle invocation from `APIGateway`,
store data into the previous `DynamoDB` table, and handle query for assignments.

- Test invoke the API to get a status code

The names of IAM role, Lambda function, DynamoDB table, API...can
be configured at the top of the `script.sh` file

`upload_DB.py` contains the code that will be in the Lambda function.

`role-trust-policy.json` contains the JSON template of the role
trust policy that allows the use of Lambda

`script.md` shows each command and its expected output
