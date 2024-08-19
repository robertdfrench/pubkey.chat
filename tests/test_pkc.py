# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
#
# Copyright 2024 Robert D. French
import base64
import json
import pathlib
import pytest
import tempfile
import typing
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
    rest_client = FakeRestClient(
            ['cf971016ea65ef5ae050d86ae26249a985e0e0fcf8cf063a55e23c24a9944762'])
    client = pkc.ChatAPIClient(pkc.API_BASE_URL, rest_client)
    head = client.get_head('default')
    assert head == 'cf971016ea65ef5ae050d86ae26249a985e0e0fcf8cf063a55e23c24a9944762'


def test_bad_head():
    rest_client = FakeRestClient(['corrupted response'])
    client = pkc.ChatAPIClient(pkc.API_BASE_URL, rest_client)
    head = client.get_head('default')
    assert head == ''


def test_no_head():
    rest_client = FakeRestClient([None])
    client = pkc.ChatAPIClient(pkc.API_BASE_URL, rest_client)
    head = client.get_head('default')
    assert head == ''


def test_get_message():
    """
    Get a message from the chat service
    """
    rest_client = FakeRestClient([
        json.dumps(
            {
                'profile': 'robertdfrench',
                'body': 'Ygo=',
                'signature': 'LS0tLS1CRUdJTiBTU0ggU0lHTkFUVVJFLS0tLS0KVTFOSVUwbEhBQUFBQVFBQUFSY0FBQUFIYzNOb0xYSnpZUUFBQUFNQkFBRUFBQUVCQU16eGUrdGo4Nk44TnhvajRXOUJWWApuSG56VzBScXlrcmtDZ2xvZFBNbjd5Y2ZMcWpTdGNBTE15STBsZ24zSmVIZHU4R0xiTlpYMkNlL0huN0hHMWVtNERUN096CnhaUXpwcTZ2SmR0MFMzVi8zK0w2TW1URC9JQURSNzRYblIyRWtZUGg0UXJ1QzhSMTVuZ0tKQ29xcC8vWEN1d3pBWmlzQjQKNG1OdXJWTWlGR01pQkpnWUpJUEFKcjk3OWdkdm1hM1hvWnFGaTUrdkc4TmhRMXlQTHZuRTZCaHdLQjdqU0xjQllIVDl2UwpJeDdKOCswRjNYZE9Xd0VScGZwQzhUeS8zVVhtUWVMa1RzQi9INWNGRFB4RHJLMjVqVWpvZDhleGtYajJERC9VYW44VWhrCjZDVGJEeFRmNlRKK3ZwSXhSM2VRVWVDU1BpS2prOTNzaVJCcUY0NzhFQUFBQU5kMjFoY0VCM2JXRndMbVJsZGdBQUFBQUEKQUFBR2MyaGhOVEV5QUFBQkZBQUFBQXh5YzJFdGMyaGhNaTAxTVRJQUFBRUFZc2RBNXRPQlY3a2pGbVpnQktlRUhtNkw1ZwpkMTk0Z01nV0hRZWdwUityTWZEUHpaQVEwMlJhaExrK0FncWxUM292MTEwS29YbGFzQlJweVpaMW1DcTE0ZjRSMWpwaXJFCmRXbzBWUXhvL1c3NlFMb2F5UjFucFdHZTZVZWZ0eGIvN0FOM05Va3ZCaVYvRStEd0drOTlRTSt5Y3M1SnR2dk1XK2Z3Y0oKaFVqeStteXRkcjUrSWZha09pM2hpS2RiZzMzMVZYWVJ2S1VuS05rUnJvcnhYbTdBbTBsaDlCWDROWGplbUFVeGlMbXpFNAp2QWhZakxldkZPejBua052eVpzbXRYaUx1NzBRZU5aTkJWK1NkWi83R2NkVy9nRG8rVUNHaW43YW8wdllLOUxIOHR4S0k5CmdPZVcxZ3V6WWdmM2xIVWFlaFU2ZzNpU285UlZxbnVBemNVQT09Ci0tLS0tRU5EIFNTSCBTSUdOQVRVUkUtLS0tLQo='
            }
        )
    ])
    client = pkc.ChatAPIClient(pkc.API_BASE_URL, rest_client)
    msg = client.get_message('aaa')
    assert msg.profile.username == 'robertdfrench'


def test_invalid_message():
    """
    Show that we *cannot* get an invalid message from the chat
    service.
    """
    rest_client = FakeRestClient([
        json.dumps(
            {
                'profile': 'robertdfrench',
                'body': 'aW52YWxpZCBtZXNzYWdl',
                'signature': 'LS0tLS1CRUdJTiBTU0ggU0lHTkFUVVJFLS0tLS0KVTFOSVUwbEhBQUFBQVFBQUFSY0FBQUFIYzNOb0xYSnpZUUFBQUFNQkFBRUFBQUVCQU16eGUrdGo4Nk44TnhvajRXOUJWWApuSG56VzBScXlrcmtDZ2xvZFBNbjd5Y2ZMcWpTdGNBTE15STBsZ24zSmVIZHU4R0xiTlpYMkNlL0huN0hHMWVtNERUN096CnhaUXpwcTZ2SmR0MFMzVi8zK0w2TW1URC9JQURSNzRYblIyRWtZUGg0UXJ1QzhSMTVuZ0tKQ29xcC8vWEN1d3pBWmlzQjQKNG1OdXJWTWlGR01pQkpnWUpJUEFKcjk3OWdkdm1hM1hvWnFGaTUrdkc4TmhRMXlQTHZuRTZCaHdLQjdqU0xjQllIVDl2UwpJeDdKOCswRjNYZE9Xd0VScGZwQzhUeS8zVVhtUWVMa1RzQi9INWNGRFB4RHJLMjVqVWpvZDhleGtYajJERC9VYW44VWhrCjZDVGJEeFRmNlRKK3ZwSXhSM2VRVWVDU1BpS2prOTNzaVJCcUY0NzhFQUFBQU5kMjFoY0VCM2JXRndMbVJsZGdBQUFBQUEKQUFBR2MyaGhOVEV5QUFBQkZBQUFBQXh5YzJFdGMyaGhNaTAxTVRJQUFBRUFZc2RBNXRPQlY3a2pGbVpnQktlRUhtNkw1ZwpkMTk0Z01nV0hRZWdwUityTWZEUHpaQVEwMlJhaExrK0FncWxUM292MTEwS29YbGFzQlJweVpaMW1DcTE0ZjRSMWpwaXJFCmRXbzBWUXhvL1c3NlFMb2F5UjFucFdHZTZVZWZ0eGIvN0FOM05Va3ZCaVYvRStEd0drOTlRTSt5Y3M1SnR2dk1XK2Z3Y0oKaFVqeStteXRkcjUrSWZha09pM2hpS2RiZzMzMVZYWVJ2S1VuS05rUnJvcnhYbTdBbTBsaDlCWDROWGplbUFVeGlMbXpFNAp2QWhZakxldkZPejBua052eVpzbXRYaUx1NzBRZU5aTkJWK1NkWi83R2NkVy9nRG8rVUNHaW43YW8wdllLOUxIOHR4S0k5CmdPZVcxZ3V6WWdmM2xIVWFlaFU2ZzNpU285UlZxbnVBemNVQT09Ci0tLS0tRU5EIFNTSCBTSUdOQVRVUkUtLS0tLQo='
            }
        )
    ])
    client = pkc.ChatAPIClient(pkc.API_BASE_URL, rest_client)
    msg = client.get_message('aaa')
    assert msg is None


def test_no_message():
    rest_client = FakeRestClient([None])
    client = pkc.ChatAPIClient(pkc.API_BASE_URL, rest_client)
    msg = client.get_message('aaa')
    assert msg is None



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
    def __init__(self, messages: typing.List[dict]):
        self.messages = list(messages)
        self.messages.reverse()

    def receive(self, _max_messages: int):
        if len(self.messages) == 0:
            raise Exception("End of test")
        return [self.messages.pop()]

    def delete(self, _receipt_handle: str):
        pass

def test_queue_iterate():
    msg_json_1 = '{"profile": "a", "body": "Yg==", "signature": "c"}'
    msg_json_2 = '{"profile": "d", "body": "ZQ==", "signature": "f"}'
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
    contents: typing.Dict[str, str]

    def write(self, key: str, value: str):
        self.contents[key] = value

    def read(self, key: str) -> typing.Optional[str]:
        return self.contents.get(key, None)


class MockLock:
    def __init__(self):
        self.table = dict()

    def acquire(self, topic, ttl):
        if topic in self.table:
            return False
        self.table[topic] = ttl
        return True

    def release(self, topic):
        del self.table[topic]

def test_bucket_write_message():
    interior = {"topic": "math", "text": "I love math", "parent": ""}
    body = base64.b64encode(json.dumps(interior).encode()).decode()
    msg_dict = {"profile": "a", "body": body, "signature": "b"}
    message = pkc.SignedMessage.from_dict(msg_dict)
    s3 = MockS3Wrapper(dict())
    bucket = pkc.PublicChatBucket(s3, pkc.TopicLock(MockLock()))
    bucket.write_message(message)
    print(s3.contents.keys())
    assert s3.contents[
            'messages/2c9d82c0869b078be14f21c2142a71639d9eebbe89552685418a424258e7da24']
    assert s3.contents['topics/math'] == \
        "2c9d82c0869b078be14f21c2142a71639d9eebbe89552685418a424258e7da24"


def test_bucket_update_topic():
    interior = {"topic": "math", "text": "I love math", "parent": "x"}
    body = base64.b64encode(json.dumps(interior).encode()).decode()
    msg_dict = {"profile": "a", "body": body, "signature": "b"}
    message = pkc.SignedMessage.from_dict(msg_dict)
    s3 = MockS3Wrapper({"topics/math": "x"})
    bucket = pkc.PublicChatBucket(s3, pkc.TopicLock(MockLock()))
    bucket.write_message(message)
    assert s3.contents['topics/math'] == \
        "1b209d90f7ebcfab4945827cb4f670da6247eee9a4777bc3bafc46805197576b"


def test_bucket_race_condition():
    interior = {"topic": "math", "text": "I love math", "parent": "x"}
    body = base64.b64encode(json.dumps(interior).encode()).decode()
    msg_dict = {"profile": "a", "body": body, "signature": "b"}
    message = pkc.SignedMessage.from_dict(msg_dict)
    s3 = MockS3Wrapper({"topics/math": "x"})
    lock = MockLock()
    lock.table['math'] = 1
    bucket = pkc.PublicChatBucket(s3, pkc.TopicLock(lock))
    with pytest.raises(Exception):
        bucket.write_message(message)


def test_message_is_valid():
    profile = pkc.Profile("robertdfrench")
    message = pkc.SignedMessage.from_raw_parts(profile, "tests/message.txt")
    assert message.is_valid()


def test_interior_dumps():
    x = pkc.InteriorMessage("a", "b", "c")
    assert x.dumps() == '{"topic": "a", "parent": "b", "text": "c"}'

def test_chat_session_interior():
    p = pkc.ChatPointer("a")
    i = p.new_interior_message("b")
    assert i.topic == "a"
    assert i.parent == ""
    assert i.text == "b"

def test_chat_session_update():
    p = pkc.ChatPointer("a")
    assert p.update_parent("x")
    assert p.parent == "x"
    assert not p.update_parent("x")

def test_chat_config():
    config = pkc.ChatConfig("a", "b")
    with tempfile.NamedTemporaryFile() as f:
        config.dump(f.name)
        config = pkc.ChatConfig.load(f.name)
        assert config.username == "a"
        assert str(config.key_path) == "b"

def test_daemon_config():
    config = pkc.DaemonConfig.load("tests/test_chat.ini")
    assert config.region == "a"
    assert config.bucket_name == "b"
    assert config.table_name == "c"
    assert config.queue_name == "d"

def test_topic():
    t = pkc.Topic("number-theory")
    assert str(t) == "number-theory"
