import json
import hashlib
import os
import boto3
import time
import subprocess
import configparser
from botocore.exceptions import ClientError

config = configparser.ConfigParser()
config.read("/etc/chat.ini")

# AWS Clients
s3_client = boto3.client('s3', region_name=config['DEFAULT']['region'])
sqs_client = boto3.client('sqs', region_name=config['DEFAULT']['region'])

# Environment Variables
QUEUE_URL = config['DEFAULT']['queue_url']
BUCKET_NAME = config['DEFAULT']['bucket_name']


def compute_message_name(body: str) -> str:
    byte_string = body.encode('utf-8')
    digest = hashlib.sha256()
    digest.update(byte_string)
    return digest.hexdigest()
    

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
            message_name = compute_message_name(record['body'])
            message = json.loads(record['Body'])
            profile = message['profile']

            # Write the message to S3
            s3_client.put_object(
                Bucket=BUCKET_NAME,
                Key=f'messages/{message_name}',
                Body=record['Body']
            )

            # Update the TOPIC for profile
            s3_client.put_object(
                Bucket=BUCKET_NAME,
                Key=f'topics/{profile}',
                Body=message_name
            )
            
            # Delete the message from SQS
            sqs_client.delete_message(
                QueueUrl=QUEUE_URL,
                ReceiptHandle=record['ReceiptHandle']
            )

if __name__ == "__main__":
    process_messages()
