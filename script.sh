#!/bin/zsh
role_name="upload-cli-sh"
function_name="upload-test-sh"
runtime="python3.7"
lambda_file_path="fileb://upload_DB.py.zip"
lambda_function_handler="upload_DB.lambda_handler"
api_name="api-upload-sh"
table_name="upload-table-sh"
path_part="cli-test-sh"
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
        --path-part ${path_part} \
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

# Create GET method
aws apigateway put-method --rest-api-id ${rest_api_id} \
       --resource-id ${resource_id} \
       --http-method GET \
       --authorization-type "NONE" \
       --api-key-required

# Create Lambda Function Integration to the Lambda function
aws apigateway put-integration \
      --rest-api-id ${rest_api_id} \
      --resource-id ${resource_id} \
      --http-method GET \
      --type AWS \
      --integration-http-method GET \
      --uri arn:aws:apigateway:us-east-2:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-2:${account}:function:${function_name}/invocations


# Deploy to stage DEV
aws apigateway create-deployment \
      --rest-api-id ${rest_api_id} \
      --stage-name DEV

# Create API Key
aws apigateway create-api-key --name upload-API-key --enabled

# Add permission to lambda function to invoked by POST method
aws lambda add-permission \
      --function-name ${function_name} \
      --action "lambda:InvokeFunction" \
      --statement-id 1 \
      --principal apigateway.amazonaws.com \
      --source-arn "arn:aws:execute-api:us-east-2:${account}:${rest_api_id}/*/POST/${path_part}"

# Add permission to lambda function to invoked by GET method
aws lambda add-permission \
      --function-name ${function_name} \
      --action "lambda:InvokeFunction" \
      --statement-id 2 \
      --principal apigateway.amazonaws.com \
      --source-arn "arn:aws:execute-api:us-east-2:${account}:${rest_api_id}/*/GET/${path_part}"

# Create table
aws dynamodb create-table \
      --table-name ${table_name} \
      --attribute-definitions AttributeName=ID,AttributeType=S \
      --key-schema AttributeName=ID,KeyType=HASH \
      --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5

aws apigateway test-invoke-method --rest-api-id ${rest_api_id} \
  --resource-id ${resource_id} --http-method POST --path-with-query-string "" \
  --body "{\"item\":\"test\"}" --query "status"