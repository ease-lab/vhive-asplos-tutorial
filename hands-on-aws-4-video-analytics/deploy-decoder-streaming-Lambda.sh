#!/bin/bash

aws lambda create-function --function-name streaming-$UNIQUE_ID \
--package-type Image \
--code ImageUri="705254273855.dkr.ecr.us-west-1.amazonaws.com/video-analytics-streaming-aws:latest" \
--role $LAMBDA_ROLE_ARN \
--timeout 120 \
--memory-size 4096 \
--environment Variables="{BUCKET_NAME=$UNIQUE_ID,DECODER_FUNCTION=decoder-$UNIQUE_ID}" \
--tracing-config Mode=Active \
--publish

aws lambda create-function --function-name decoder-$UNIQUE_ID \
--package-type Image \
--code ImageUri="705254273855.dkr.ecr.us-west-1.amazonaws.com/video-analytics-decoder-aws:latest" \
--role $LAMBDA_ROLE_ARN \
--timeout 120 \
--memory-size 4096 \
--environment Variables="{BUCKET_NAME=$UNIQUE_ID,RECOG_FUNCTION=recog-$UNIQUE_ID}" \
--tracing-config Mode=Active \
--publish