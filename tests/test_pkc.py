# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
#
# Copyright 2024 Robert D. French
import pytest
import typing
import json
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
    message = pkc.Message.loads(text)
    assert message.profile.username == "a"
    assert message.body == b'b'
    assert message.signature.content == "c"


def test_dumps_message():
    """
    Load a message from a string
    """
    text = "{\"profile\": \"a\", \"body\": \"Yg==\", \"signature\": \"c\"}"
    message = pkc.Message.loads(text)
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
    message = pkc.Message.loads(text)
    client.post_message(message)
    assert rest_client.payloads[0] == {
                'profile': 'a',
                'body': 'Yg==',
                'signature': 'c'
            }
