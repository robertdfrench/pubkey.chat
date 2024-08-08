import json
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
            profile = message['profile']
            
            # Write the message to S3
            s3_client.put_object(
                Bucket=BUCKET_NAME,
                Key=f'{profile}.json',
                Body=record['Body']
            )
            
            # Update the topic file with the latest ID
            #s3_client.put_object(
            #    Bucket=BUCKET_NAME,
            #    Key=f'{topic}',
            #    Body=message_id
            #)
            
            # Delete the message from SQS
            sqs_client.delete_message(
                QueueUrl=QUEUE_URL,
                ReceiptHandle=record['ReceiptHandle']
            )

if __name__ == "__main__":
    process_messages()
