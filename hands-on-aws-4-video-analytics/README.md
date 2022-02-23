
## Hands-on AWS - 1 - Hello World
# Installing dependencies

Here we install relevant dependencies to run serverless framework.

```
!pip install awscli --upgrade --user
!npm install -g serverless
```

# Setting AWS environmental variables

Here we set up AWS environmental variables so that we will be able to deploy to our AWS account. We will need access key id, secret access key and account id. You will need to replace AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_ACCOUNT_ID with your values. Please use test account and temporary credentials or deactivate credentials after usage.

```
%env AWS_ACCESS_KEY_ID=<AWS_ACCESS_KEY_ID>
%env AWS_SECRET_ACCESS_KEY=<AWS_SECRET_ACCESS_KEY>
%env AWS_ACCOUNT_ID=<AWS_ACCOUNT_ID>
%env AWS_DEFAULT_REGION=us-west-1
```
# Create bucket
```
aws s3api create-bucket \
    --bucket firstname-lastname \
    --region us-east-1

aws s3api delete-bucket --bucket <value>
```
# Lambda deployment - object recog

Let's deploy the object recognition lambda.
First we have to create a role which can be assumed by the lambda function.

```
aws iam create-role --role-name recog-role --assume-role-policy-document ./roles/trust-policy.json
aws iam create-role --role-name decoder-role --assume-role-policy-document ./roles/trust-policy.json
aws iam create-role --role-name streaming-role --assume-role-policy-document ./roles/trust-policy.json

# delete role in case of typo
aws iam  delete-role --role-name <value>
```
create policy with the list of permissions for the lambda
```
aws iam create-policy --policy-name recog-policy --policy-document file://roles/streaming-policy.json

# delete role in case of typo
aws iam  delete-policy --policy-arn <value>
```
Now, we will attach the permissions for the above role.
```
aws iam attach-role-policy --role-name recog-role --policy-name recog-policy
```
Create lambda function from ECR image
```
aws lambda create-function --function-name recog \
--package-type Image \
--code ImageUri="356764711652.dkr.ecr.us-west-1.amazonaws.com/video-analytics-recog-aws:latest" \
--role "arn:aws:iam::356764711652:role/recog-role" \
--timeout 120 \
--memory-size 4096 \
--environment Variables={bucketName=bucketName} \
--tracing-config Mode=Active \
--publish

# delete command in case of typo
aws lambda delete-function --function-name <value>
```
# Lambda invoke - recog

Invoke Lambda using cli
```
aws lambda invoke --function-name streaming \
--cli-binary-format raw-in-base64-out \
--payload '{"transferType": "S3", "s3key": "frames/decoder-frame-1.jpg"}' response.json
```

# Lambda deployment - decoder

Let's deploy the object recognition lambda.
First we have to create a role which can be assumed by the lambda function.

```
aws iam create-role --role-name decoder-role --assume-role-policy-document ./roles/trust-policy.json
```
create policy with the list of permissions for the lambda
```
aws iam create-policy --policy-name decoder-policy --policy-document file://roles/streaming-policy.json
```
Now, we will attach the permissions for the above role.
```
aws iam attach-role-policy --role-name decoder-role --policy-name decoder-policy
```
Create lambda function from ECR image
```
aws lambda create-function --function-name decoder \
--package-type Image \
--code ImageUri="356764711652.dkr.ecr.us-west-1.amazonaws.com/video-analytics-streaming-aws:latest" \
--role "arn:aws:iam::356764711652:role/decoder-role" \
--timeout 120 \
--memory-size 4096 \
--environment Variables={bucketName=bucket} \
--tracing-config Mode=Active \
--publish

# delete command in case of typo
aws lambda delete-function --function-name <value>
```
# Lambda invoke - decoder

Invoke Lambda using cli
```
aws lambda invoke --function-name streaming \
--cli-binary-format raw-in-base64-out \
--payload '{"transferType": "S3", "s3key": "streaming-video.mp4"}' response.json
```

# Lambda deployment - streaming

Let's deploy the object recognition lambda.
First we have to create a role which can be assumed by the lambda function.

```
aws iam create-role --role-name streaming-role --assume-role-policy-document ./roles/trust-policy.json
```
create policy with the list of permissions for the lambda
```
aws iam create-policy --policy-name streaming-policy --policy-document file://roles/streaming-policy.json
```
Now, we will attach the permissions for the above role.
```
aws iam attach-role-policy --role-name streaming-role --policy-name streaming-policy
```
Create lambda function from ECR image
```
aws lambda create-function --function-name streaming \
--package-type Image \
--code ImageUri="356764711652.dkr.ecr.us-west-1.amazonaws.com/video-analytics-streaming-aws:latest" \
--role "arn:aws:iam::356764711652:role/streaming-role" \
--timeout 120 \
--memory-size 4096 \
--environment Variables={bucketName=bucket} \
--tracing-config Mode=Active \
--publish

# delete command in case of typo
aws lambda delete-function --function-name <value>
```

# Lambda invoke - streaming

Invoke Lambda using cli
```
aws lambda invoke --function-name streaming \
--cli-binary-format raw-in-base64-out \
--payload '{ "name": "bla", "TransferType": "S3" }' response.json
```
