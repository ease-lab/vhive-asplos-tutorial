
## Hands-on AWS - 1 - Hello World
# Installing dependencies

Here we install relevant dependencies to run serverless framework.

```
pip install awscli --upgrade --user
sudo apt install jq
```

# Setting AWS environmental variables

Here we set up AWS environmental variables so that we will be able to deploy to our AWS account. We will need access key id, secret access key and account id. You will need to replace AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_ACCOUNT_ID with your values. Please use test account and temporary credentials or deactivate credentials after usage.

```
export AWS_ACCESS_KEY_ID=<AWS_ACCESS_KEY_ID>
export AWS_SECRET_ACCESS_KEY=<AWS_SECRET_ACCESS_KEY>
export AWS_ACCOUNT_ID=<AWS_ACCOUNT_ID>
export AWS_DEFAULT_REGION=us-west-1
```
# Setting environmental variables

Here we set up unique environmental variables which we will be using to name our functions.

```
export UNIQUE_ID=<firstname-lastname>
```

# Create bucket
add bucket name enivironment variable.
```
aws s3api create-bucket \
    --bucket $UNIQUE_ID \
    --create-bucket-configuration LocationConstraint=us-west-1

aws s3api delete-bucket --bucket $UNIQUE_ID
```
# Lambda deployment - object recog

Let's deploy the object recognition lambda.
First we have to create a role which can be assumed by the lambda function.

```
aws iam create-role --role-name lambda-role-$UNIQUE_ID --assume-role-policy-document file://roles/lambda-role.json | jq '.Role.Arn'
# export the role variable for later use
export LAMBDA_ROLE_ARN=<arn>

# delete role in case of typo
aws iam  delete-role --role-name lambda-role-$UNIQUE_ID
```
create policy with the list of permissions for the lambda
```
aws iam create-policy --policy-name lambda-policy-$UNIQUE_ID --policy-document file://roles/lambda-policy.json | jq '.Policy.Arn'
export LAMBDA_POLICY_ARN=<arn>
# delete role in case of typo
aws iam  delete-policy --policy-arn $LAMBDA_POLICY_ARN
```
Now, we will attach the permissions for the above role.
```
aws iam attach-role-policy --role-name lambda-role-$UNIQUE_ID --policy-arn $LAMBDA_POLICY_ARN

# detach in case of typo
aws iam detach-role-policy --role-name lambda-role-$UNIQUE_ID --policy-arn $LAMBDA_POLICY_ARN
```
Create lambda function from ECR image
```
aws lambda create-function --function-name recog-$UNIQUE_ID \
--package-type Image \
--code ImageUri="705254273855.dkr.ecr.us-west-1.amazonaws.com/video-analytics-recog-aws:latest" \
--role $LAMBDA_ROLE_ARN \
--timeout 120 \
--memory-size 4096 \
--environment Variables={BUCKET_NAME=$UNIQUE_ID} \
--tracing-config Mode=Active \
--publish

# delete command in case of typo
aws lambda delete-function --function-name recog-$UNIQUE_ID
```
# Deploy decoder and streaming lambdas
```
./deploy-decoder-Streaming-Lambda.sh
```

# Lambda invoke - streaming

Invoke Lambda using cli
```
aws lambda invoke --function-name streaming-$UNIQUE_ID \
--cli-binary-format raw-in-base64-out \
--payload '{ "name": "'$UNIQUE_ID'", "TransferType": "S3" }' response.json
```

# Lambda response
```
cat ./response.json
```

# Clean up resources
```
./cleanup.sh
```