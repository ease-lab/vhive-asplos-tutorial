import boto3
import json
import io
import os

def handler(event, context):
	if 'Records' in event:
		for message in event['Records']:
			if message['body'] != 'ValueError':
				print(f"Message body:{message['body']}")
				print(f"Message id:{message['messageId']}")
				print(f"Bucket:{os.getenv('S3_BUCKET')}")
				s3_client = boto3.client('s3')
				fo = io.BytesIO(str.encode(message['body']))
				s3_client.upload_fileobj(fo, os.getenv('S3_BUCKET'), str(message['messageId']))
			else:
				raise ValueError
	return {}