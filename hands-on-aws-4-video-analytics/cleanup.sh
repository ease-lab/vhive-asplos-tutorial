#!/bin/bash

aws lambda delete-function --function-name streaming-$HASH
aws lambda delete-function --function-name recog-$HASH
aws lambda delete-function --function-name decoder-$HASH

aws iam detach-role-policy --role-name lambda-role-$HASH --policy-arn $LAMBDA_POLICY_ARN
aws iam  delete-role --role-name lambda-role-$HASH
aws iam  delete-policy --policy-arn $LAMBDA_POLICY_ARN
aws s3 rb s3://$HASH --force