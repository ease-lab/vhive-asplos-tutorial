#!/bin/bash

aws lambda delete-function --function-name streaming-$UNIQUE_ID
aws lambda delete-function --function-name recog-$UNIQUE_ID
aws lambda delete-function --function-name decoder-$UNIQUE_ID

aws iam detach-role-policy --role-name lambda-role-$UNIQUE_ID --policy-arn $LAMBDA_POLICY_ARN
aws iam  delete-role --role-name lambda-role-$UNIQUE_ID
aws iam  delete-policy --policy-arn $LAMBDA_POLICY_ARN
aws s3api delete-bucket --bucket $UNIQUE_ID