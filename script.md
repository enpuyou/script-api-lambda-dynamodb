### Create Role
```
iam create-role  --role-name upload-cli --assume-role-policy-document file://role-trust-policy.json


{
    "Role": {
        "Path": "/",
        "RoleName": "upload-cli",
        "RoleId": "AROAVHPXC5A6K4Q7EJPT6",
        "Arn": "arn:aws:iam::359684827196:role/upload-cli",
        "CreateDate": "2019-12-23T06:57:25Z",
        "AssumeRolePolicyDocument": {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": {
                        "Service": "lambda.amazonaws.com"
                    },
                    "Action": "sts:AssumeRole"
                }
            ]
        }
    }
}
```


### Attach policies to role for the lambda function
```
iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess --role-name upload-cli
iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs --role-name upload-cli
iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaDynamoDBExecutionRole --role-name upload-cli
iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole --role-name upload-cli
```

```
lambda create-function --function-name upload-helloworld \
--zip-file fileb://upload_DB.py.zip --handler upload_DB.lambda_handler.lambda_handler --runtime python3.7 \
--role arn:aws:iam::359684827196:role/upload-cli


{
    "FunctionName": "upload-helloworld",
    "FunctionArn": "arn:aws:lambda:us-east-2:359684827196:function:upload-helloworld",
    "Runtime": "python3.7",
    "Role": "arn:aws:iam::359684827196:role/upload-cli",
    "Handler": "upload-helloworld.lambda_handler",
    "CodeSize": 1074,
    "Description": "",
    "Timeout": 3,
    "MemorySize": 128,
    "LastModified": "2019-12-23T07:01:04.190+0000",
    "CodeSha256": "F86SHuMROEfd47qwm7FbyIWOo5vQG7xoCa0VwDYylwE=",
    "Version": "$LATEST",
    "TracingConfig": {
        "Mode": "PassThrough"
    },
    "RevisionId": "67222765-b2f1-4e4e-9910-d45e91813bbc",
    "State": "Active",
    "LastUpdateStatus": "Successful"
}
```

### Create API
```
apigateway create-rest-api --name 'upload-helloworld'


{
    "id": "z2fjwjvl73",
    "name": "upload-helloworld",
    "createdDate": 1577085934,
    "apiKeySource": "HEADER",
    "endpointConfiguration": {
        "types": [
            "EDGE"
        ]
    }
}
```

```
apigateway get-resources --rest-api-id z2fjwjvl73


{
    "items": [
        {
            "id": "osq1h1g7p2",
            "path": "/"
        }
    ]
}
```

```
apigateway create-resource --rest-api-id z2fjwjvl73 \
      --parent-id osq1h1g7p2 \
      --path-part cli-test


{
    "id": "sqxy70",
    "parentId": "osq1h1g7p2",
    "pathPart": "cli-test",
    "path": "/cli-test"
}
```

### Create method POST
```
apigateway put-method --rest-api-id z2fjwjvl73 \
       --resource-id sqxy70 \
       --http-method POST \
       --authorization-type "NONE" \
       --api-key-required


{
    "httpMethod": "POST",
    "authorizationType": "NONE",
    "apiKeyRequired": true
}
```

### Set up lambda proxy integration
```
apigateway put-integration \
        --rest-api-id z2fjwjvl73 \
        --resource-id sqxy70 \
        --http-method POST \
        --type AWS_PROXY \
        --integration-http-method POST \
        --uri arn:aws:apigateway:us-east-2:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-2:359684827196:function:upload-helloworld/invocations


{
    "type": "AWS_PROXY",
    "httpMethod": "POST",
    "uri": "arn:aws:apigateway:us-east-2:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-2:359684827196:function:upload-helloworld/invocations",
    "passthroughBehavior": "WHEN_NO_MATCH",
    "timeoutInMillis": 29000,
    "cacheNamespace": "sqxy70",
    "cacheKeyParameters": []
}
```

### Deploy
```
apigateway create-deployment --rest-api-id z2fjwjvl73 --stage-name test

{
    "id": "w88458",
    "createdDate": 1577087587
}
```

### Create API Key
```
apigateway create-api-key --name test-API-key --enabled
{
    "id": "epxjk6dpr3",
    "value": "FB3tecmAFD1ij3aSsNP2P280nHVRvijN9Mn1Suw1",
    "name": "test-API-key",
    "enabled": true,
    "createdDate": 1577132596,
    "lastUpdatedDate": 1577132596,
    "stageKeys": []
}
```

### Connect Api gateway to the lambda function
```
lambda add-permission --function-name upload-helloworld --action "lambda:InvokeFunction" --statement-id 2 --principal apigateway.amazonaws.com --source-arn arn:aws:execute-api:us-east-2:359684827196:z2fjwjvl73/*/POST/cli-test


{
    "Statement": "{\"Sid\":\"2\",\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"apigateway.amazonaws.com\"},\"Action\":\"lambda:InvokeFunction\",\"Resource\":\"arn:aws:lambda:us-east-2:359684827196:function:upload-helloworld\",\"Condition\":{\"ArnLike\":{\"AWS:SourceArn\":\"arn:aws:execute-api:us-east-2:359684827196:z2fjwjvl73/*/POST/cli-test\"}}}"
}
```

### Create table
```
dynamodb create-table --table-name cli-helloworld --attribute-definitions AttributeName=ID,AttributeType=S --key-schema AttributeName=ID,KeyType=HASH --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5

{
    "TableDescription": {
        "AttributeDefinitions": [
            {
                "AttributeName": "ID",
                "AttributeType": "S"
            }
        ],
        "TableName": "cli-helloworld",
        "KeySchema": [
            {
                "AttributeName": "ID",
                "KeyType": "HASH"
            }
        ],
        "TableStatus": "CREATING",
        "CreationDateTime": 1577142257.938,
        "ProvisionedThroughput": {
            "NumberOfDecreasesToday": 0,
            "ReadCapacityUnits": 5,
            "WriteCapacityUnits": 5
        },
        "TableSizeBytes": 0,
        "ItemCount": 0,
        "TableArn": "arn:aws:dynamodb:us-east-2:359684827196:table/cli-helloworld",
        "TableId": "47e21b23-170f-4698-99f2-da1fcc3e587a"
    }
}
```
