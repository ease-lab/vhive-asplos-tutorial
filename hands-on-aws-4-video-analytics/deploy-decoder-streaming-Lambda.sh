#!/bin/bash

aws lambda create-function --function-name streaming-$HASH \
--package-type Image \
--code ImageUri="705254273855.dkr.ecr.us-west-1.amazonaws.com/video-analytics-streaming-aws:latest" \
--role $LAMBDA_ROLE_ARN \
--timeout 120 \
--memory-size 4096 \
--environment Variables="{BUCKET_NAME=$HASH,DECODER_FUNCTION=decoder-$HASH}" \
--tracing-config Mode=Active \
--publish

aws lambda create-function --function-name decoder-$HASH \
--package-type Image \
--code ImageUri="705254273855.dkr.ecr.us-west-1.amazonaws.com/video-analytics-decoder-aws:latest" \
--role $LAMBDA_ROLE_ARN \
--timeout 120 \
--memory-size 4096 \
--environment Variables="{BUCKET_NAME=$HASH,RECOG_FUNCTION=recog-$HASH}" \
--tracing-config Mode=Active \
--publish

sleep 30s