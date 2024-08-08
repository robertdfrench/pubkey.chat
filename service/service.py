import json
import os
import boto3
import time
import subprocess
from botocore.exceptions import ClientError

# AWS Clients
s3_client = boto3.client('s3')
sqs_client = boto3.client('sqs')

# Environment Variables
QUEUE_URL = os.getenv('QUEUE_URL')
BUCKET_NAME = os.getenv('BUCKET_NAME')

def process_messages():
    while True:
        response = sqs_client.receive_message(
            QueueUrl=QUEUE_URL,
            MaxNumberOfMessages=1,
            WaitTimeSeconds=20
        )
        messages = response.get('Messages', [])
        if not messages:
            continue

        for record in messages:
            message = json.loads(record['Body'])
            topic = message['topic']
            message_id = message['id']
            
            # Write the message to S3
            s3_client.put_object(
                Bucket=BUCKET_NAME,
                Key=f'{message_id}.json',
                Body=json.dumps(message)
            )
            
            # Update the topic file with the latest ID
            s3_client.put_object(
                Bucket=BUCKET_NAME,
                Key=f'{topic}',
                Body=message_id
            )
            
            # Delete the message from SQS
            sqs_client.delete_message(
                QueueUrl=QUEUE_URL,
                ReceiptHandle=record['ReceiptHandle']
            )

if __name__ == "__main__":
    process_messages()
