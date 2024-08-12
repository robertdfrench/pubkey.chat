# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
#
# Copyright 2024 Robert D. French
import pytest
import typing
import json
from dataclasses import dataclass
from . import pkc


def test_url():
    """
    Ensure that we have a PKC API URL defined
    """
    assert pkc.API_BASE_URL


class FakeRestClient:
    responses: typing.List[str]
    urls: typing.List[str]
    payloads: typing.List[dict]

    def __init__(self, responses):
        self.responses = list(responses)
        self.responses.reverse()
        self.urls = list()
        self.payloads = list()

    def get(self, url: str) -> str:
        self.urls.append(url)
        self.payloads.append(None)
        return self.responses.pop()

    def post_json(self, url: str, payload: dict) -> str:
        self.urls.append(url)
        self.payloads.append(payload)
        return self.responses.pop()
        

def test_loads_message():
    """
    Load a message from a string
    """
    text = "{\"profile\": \"a\", \"body\": \"Yg==\", \"signature\": \"c\"}"
    message = pkc.SignedMessage.loads(text)
    assert message.profile.username == "a"
    assert message.body == b'b'
    assert message.signature.content == "c"


def test_dumps_message():
    """
    Load a message from a string
    """
    text = "{\"profile\": \"a\", \"body\": \"Yg==\", \"signature\": \"c\"}"
    message = pkc.SignedMessage.loads(text)
    assert message.dumps() == text


def test_get_head():
    """
    Get the HEAD of a topic from the chat service
    """
    rest_client = FakeRestClient(['aaa'])
    client = pkc.ChatAPIClient(pkc.API_BASE_URL, rest_client)
    head = client.get_head('default')
    assert head == 'aaa'


def test_get_message():
    """
    Get a message from the chat service
    """
    rest_client = FakeRestClient([
        json.dumps(
            {
                'profile': 'a',
                'body': 'Yg==',
                'signature': 'c'
            }
        )
    ])
    client = pkc.ChatAPIClient(pkc.API_BASE_URL, rest_client)
    msg = client.get_message('aaa')
    assert msg.profile.username == 'a'


def test_post_message():
    """
    Post a message to the chat service
    """
    rest_client = FakeRestClient([""])
    client = pkc.ChatAPIClient(pkc.API_BASE_URL, rest_client)
    text = "{\"profile\": \"a\", \"body\": \"Yg==\", \"signature\": \"c\"}"
    message = pkc.SignedMessage.loads(text)
    client.post_message(message)
    assert rest_client.payloads[0] == {
                'profile': 'a',
                'body': 'Yg==',
                'signature': 'c'
            }

class MockSQSWrapper:
    def __init__(self, messages: list[dict]):
        self.messages = list(messages)
        self.messages.reverse()

    def receive(self, _max_messages: int):
        if len(self.messages) == 0:
            raise Exception("End of test")
        return [self.messages.pop()]

    def delete(self, _receipt_handle: str):
        pass

def test_queue_iterate():
    msg_json_1 = '{"profile": "a", "body": "b", "signature": "c"}'
    msg_json_2 = '{"profile": "d", "body": "e", "signature": "f"}'
    messages = [
            {'Body': msg_json_1, 'ReceiptHandle': 'a'},
            {'Body': msg_json_2, 'ReceiptHandle': 'b'},
        ]
    sqs = MockSQSWrapper(messages)
    queue = pkc.Queue(sqs)
    bodies = []
    try:
        for message in queue.messages():
            bodies.append(message.body.decode())
    except Exception as e:
        assert(str(e) == "End of test")
    assert bodies[0] == 'b'
    assert bodies[1] == 'e'

@dataclass
class MockS3Wrapper:
    contents: dict[str, str]

    def write(self, key: str, value: str):
        self.contents[key] = value

    def read(self, key: str) -> str | None:
        return self.contents.get(key, None)

def test_bucket_write_message():
    interior = {"topic": "math", "data": "I love math", "parent": ""}
    msg_dict = {"profile": "a", "body": json.dumps(interior), "signature": "b"}
    message = pkc.SignedMessage.from_dict(msg_dict)
    s3 = MockS3Wrapper(dict())
    bucket = pkc.Bucket(s3)
    bucket.write_message(message)
    assert s3.contents['/messages/502217a81ca8d389786c82c7cf1e20f4d1fa3faf6429572c1476cdeca941ed0c']
    assert s3.contents['/topics/math'] == \
        "502217a81ca8d389786c82c7cf1e20f4d1fa3faf6429572c1476cdeca941ed0c"

def test_bucket_update_topic():
    interior = {"topic": "math", "data": "I love math", "parent": "x"}
    msg_dict = {"profile": "a", "body": json.dumps(interior), "signature": "b"}
    message = pkc.SignedMessage.from_dict(msg_dict)
    s3 = MockS3Wrapper({"/topics/math": "x"})
    bucket = pkc.Bucket(s3)
    bucket.write_message(message)
    assert s3.contents['/topics/math'] == \
        "da9d29ca29888d1c81bbf3a7bf3ff2ef01f3f6de8a6f273e38104a4355872e7b"


def test_message_is_valid():
    profile = pkc.Profile("robertdfrench")
    message = pkc.SignedMessage.from_raw_parts(profile, "tests/message.txt")
    assert message.is_valid()
