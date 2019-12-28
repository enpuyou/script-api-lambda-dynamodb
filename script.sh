#!/bin/bash
# shellcheck disable=SC2086

# Settings
# Role Name for IAM Role
role_name="upload-cli-sh"
# Lambda function name
function_name="upload-test-sh"
# Language for Lambda Function
runtime="python3.7"
# Path to lambda function zip file
lambda_file_path="fileb://upload_DB.py.zip"
# Lambda function handler (handler module in the file)
lambda_function_handler="upload_DB.lambda_handler"
# API Gateway Api name
api_name="api-upload-sh"
# DynamoDB Table name
table_name="upload-table-sh"
# Name for part of the API path
api_path="cli-test-sh"
# Name for the api key
api_key_name="upload-API-key"
# Name for the deployment stage name
stage_name="DEV"
# Get Amazon account information
account=$(aws sts get-caller-identity --query "Account" --output=text)


# Create Role
role_arn=$(aws iam create-role \
        --role-name ${role_name} \
        --assume-role-policy-document file://role-trust-policy.json \
        --query "Role.Arn" \
        --output=text)

# Add policies to the role created
aws iam attach-role-policy \
        --policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess \
        --role-name ${role_name}
aws iam attach-role-policy \
        --policy-arn arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs \
        --role-name ${role_name}
aws iam attach-role-policy \
        --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaDynamoDBExecutionRole \
        --role-name ${role_name}
aws iam attach-role-policy \
        --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole \
        --role-name ${role_name}

# Pause for the time takes aws to create role
sleep 10s

# Create Lambda Function
aws lambda create-function \
        --function-name ${function_name} \
        --zip-file ${lambda_file_path} \
        --handler ${lambda_function_handler} \
        --runtime ${runtime} \
        --role ${role_arn}

# Create a Rest API
rest_api_id=$(aws apigateway create-rest-api \
        --name ${api_name} \
        --query "id" \
        --output=text)

# Get the parent id of the Rest API created
parent_id=$(aws apigateway get-resources \
        --rest-api-id ${rest_api_id} \
        --query "items[0].id" \
        --output=text)

# Create a resource under the current API
resource_id=$(aws apigateway create-resource \
        --rest-api-id ${rest_api_id} \
        --parent-id ${parent_id} \
        --path-part ${api_path} \
        --query "id" \
        --output=text)

# Create POST method
aws apigateway put-method --rest-api-id ${rest_api_id} \
       --resource-id ${resource_id} \
       --http-method POST \
       --authorization-type "NONE" \
       --api-key-required

# Create Lambda Proxy Integration to the Lambda function
aws apigateway put-integration \
      --rest-api-id ${rest_api_id} \
      --resource-id ${resource_id} \
      --http-method POST \
      --type AWS_PROXY \
      --integration-http-method POST \
      --uri arn:aws:apigateway:us-east-2:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-2:${account}:function:${function_name}/invocations

# Create GET method only allows IAM user to invoke
aws apigateway put-method --rest-api-id ${rest_api_id} \
       --resource-id ${resource_id} \
       --http-method GET \
       --authorization-type "AWS_IAM" \
       --api-key-required

# Create Lambda Function Integration to the Lambda function
aws apigateway put-integration \
      --rest-api-id ${rest_api_id} \
      --resource-id ${resource_id} \
      --http-method GET \
      --type AWS_PROXY \
      --integration-http-method POST \
      --uri arn:aws:apigateway:us-east-2:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-2:${account}:function:${function_name}/invocations


# Create API Key
api_key_id=$(aws apigateway create-api-key \
            --name ${api_key_name} \
            --enabled \
            --query "id" \
            --output=text)

# Get API key value
API_KEY=$(apigateway get-api-key \
      --api-key ${api_key_id} \
      --include-value \
      --query "value" \
      --output=text)


# export GATOR_API_KEY and GATOR_ENDPOINT
export GATOR_API_KEY=$API_KEY
export GATOR_ENDPOINT=https://${rest_api_id}.execute-api.us-east-2.amazonaws.com/${stage_name}/${api_path}


# Deploy to stage
aws apigateway create-deployment \
      --rest-api-id ${rest_api_id} \
      --stage-name ${stage_name}


# Add permission to lambda function to invoked by POST method
aws lambda add-permission \
      --function-name ${function_name} \
      --action "lambda:InvokeFunction" \
      --statement-id 1 \
      --principal apigateway.amazonaws.com \
      --source-arn "arn:aws:execute-api:us-east-2:${account}:${rest_api_id}/*/POST/${api_path}"

# Add permission to lambda function to invoked by GET method
aws lambda add-permission \
      --function-name ${function_name} \
      --action "lambda:InvokeFunction" \
      --statement-id 2 \
      --principal apigateway.amazonaws.com \
      --source-arn "arn:aws:execute-api:us-east-2:${account}:${rest_api_id}/*/GET/${api_path}"

# Create Usage plan
usage_plan_id=$(aws apigateway create-usage-plan \
      --name "My Usage Plan" \
      --description "A new usage plan" \
      --throttle burstLimit=10,rateLimit=5 \
      --quota limit=500,offset=0,period=MONTH \
      --api-stages apiId=0aw1ei1hti${rest_api_id},stage=${stage_name})

# Add the created key to this usage plan
aws apigateway create-usage-plan-key \
      --usage-plan-id ${usage_plan_id} \
      --key-type "API_KEY" \
      --key-id ${api_key_id}

# Create table
aws dynamodb create-table \
      --table-name ${table_name} \
      --attribute-definitions AttributeName=ID,AttributeType=S \
      --key-schema AttributeName=ID,KeyType=HASH \
      --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5

sleep 3s

# Test Invoke to get status code 200
aws apigateway test-invoke-method --rest-api-id ${rest_api_id} \
      --resource-id ${resource_id} --http-method POST --path-with-query-string "" \
      --body "{\"item\":\"test\"}" --query "status"
