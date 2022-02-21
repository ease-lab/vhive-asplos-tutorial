import boto3
import json
import io
import os

def handler(event, context):
	print(event)
	return {
		'statusCode': 200,
		'body': f'HelloWorld {event}'
	}