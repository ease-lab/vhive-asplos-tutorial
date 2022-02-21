import boto3
import json
import io
import os

def handler_map(event, context):
	event['tasks'] = [
		{
			'task_id': 1
		},
		{
			'task_id': 2
		},
		{
			'task_id': 3
		}
	]
	print(event)
	return event

def handler_task(event, context):
	event['result'] = event['task_id'] + 1
	print(event)
	return event

def handler_reduce(event, context):
	print(event)
	result_sum = sum([task['result'] for task in event['map_result']])
	print(result_sum)
	return {'result': result_sum}
