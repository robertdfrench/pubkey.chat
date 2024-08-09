#!/usr/bin/python3
import base64
import boto3
from botocore.exceptions import ClientError
import configparser
from dataclasses import dataclass
from enum import Enum, auto
import json
import hashlib
import os
from urllib import request
import subprocess
import sys
import tempfile
import time
from typing import List
from botocore.exceptions import ClientError


config = configparser.ConfigParser()
config.read("/etc/chat.ini")

# AWS Clients
s3_client = boto3.client('s3', region_name=config['DEFAULT']['region'])
sqs_client = boto3.client('sqs', region_name=config['DEFAULT']['region'])

# Environment Variables
QUEUE_URL = config['DEFAULT']['queue_url']
BUCKET_NAME = config['DEFAULT']['bucket_name']
NAMESPACE = "wmap@wmap.dev"
    

def main():
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
            with tempfile.NamedTemporaryFile() as f:
                f.write(bytes(record['Body'], 'utf-8'))
                f.flush()
                sigfile = f.name + ".sig"
                message = Message.load(f.name)   # Load message from disk
                message.signature.dump(sigfile)  # Extract signature temporarily
                valid = message.profile.verify_signed_data(
                        message.body, sigfile)   # Check signature against profile & body
                os.remove(sigfile)               # Remove temporary signature

            if valid:
                message_name = compute_message_name(record['Body'])
                interior_message = json.loads(message.body)
                expected_parent = interior_message['parent']
                topic = interior_message['topic']

                actual_parent = topic_parent(s3_client, topic) 
                if ((not actual_parent) or (actual_parent == expected_parent)):
                    # Write the message to S3
                    s3_client.put_object(
                        Bucket=BUCKET_NAME,
                        Key=f'messages/{message_name}',
                        Body=record['Body']
                    )

                    # Update the TOPIC for profile
                    s3_client.put_object(
                        Bucket=BUCKET_NAME,
                        Key=f'topics/{topic}',
                        Body=message_name
                    )

            # Delete the message from SQS
            sqs_client.delete_message(
                QueueUrl=QUEUE_URL,
                ReceiptHandle=record['ReceiptHandle']
            )


def topic_parent(s3_client, topic):
    try:
        o = s3_client.get_object(Bucket=BUCKET_NAME, Key=f'topics/{topic}')
        actual_parent = o['Body'].read().decode('utf-8')
        return actual_parent
    except:
        return None


def compute_message_name(body: str) -> str:
    byte_string = body.encode('utf-8')
    digest = hashlib.sha256()
    digest.update(byte_string)
    return digest.hexdigest()


class Algorithm(Enum):
    """
    Allowable algorithms for SSH signing keys.

    Not all SSH key algorithms support signing. RSA and ED25519 do, so when
    parsing an Allowed Signers record or an Authorized Key record, we want to
    restrict ourselves to those two algorithms.
    """
    RSA = auto()
    ED25519 = auto()

    @classmethod
    def parse(cls, string: str) -> 'Algorithm':
        """
        Attempt to parse a string into one of these Algorithm enum instances.

        Parameters:
        - string: a string which may or may not be a valid SSH signing
          algorithm.

        Raises:
        - Exception: if the string does not match an allowed algorithm.
        """
        if string == "ssh-rsa":
            return cls.RSA
        elif string == "ssh-ed25519":
            return cls.ED25519
        else:
            raise Exception("Unknown ssh key algorithm")

    def __str__(self):
        if self == Algorithm.RSA:
            return "ssh-rsa"
        if self == Algorithm.ED25519:
            return "ssh-ed25519"


@dataclass
class AuthorizedKey:
    """
    Representation of an Authorized Key entry, as seen in an
    ~/.ssh/authorized_keys file.

    See the AUTHORIZED_KEYS_FILE_FORMAT section of the sshd(8) man page for
    more information about what these files look like.
    """
    algorithm: Algorithm
    material: str
    comment: str

    @classmethod
    def parse(cls, string: str) -> 'AuthorizedKey':
        """
        Parse an authorized keys entry into its constituent parts. Such entries
        take the following form:

            ssh-rsa ABC...123 username@example.com (other comments)

        Parameters:
        - string: a string which ought to be a normal-looking authorized keys
          entry.
        """
        parts = string.split()
        algorithm = Algorithm.parse(parts[0])
        return cls(algorithm, parts[1], " ".join(parts[2:]))

    def into_allowed_signer(self, profile: 'Profile') -> str:
        """
        Convert this authorized keys entry into an ALLOWED SIGNERS entry. Such
        records take the following form:

            username namespacs="wmap@wmap.dev" ssh-rsa ABC...123

        More information on ALLOWED SIGNERS can be found in the `ssh-keygen(1)`
        manual page.

        Parameters:
        - profile: the profile of the GitHub user for whom we'd like to build
          the ALLOWED SIGNERS record.
        """
        principal = profile.username
        algorithm = str(self.algorithm)
        material = self.material
        return f"{principal} namespaces=\"{NAMESPACE}\" {algorithm} {material}"


@dataclass
class Profile:
    """
    The GitHub profile associated with `username`
    """
    username: str

    def url(self) -> str:
        """URL for this user's github profile"""
        return f"https://github.com/{self.username}"

    def authorized_keys_url(self) -> str:
        """URL for this user's ssh public keys"""
        return self.url() + ".keys"

    def authorized_keys(self) -> List[AuthorizedKey]:
        """
        Grab the user's Authorized Keys from GitHub, transforming each of them
        into an AuthorizedKey object.
        """
        with request.urlopen(self.authorized_keys_url()) as response:
            lines = response.read().decode().splitlines()
            return [AuthorizedKey.parse(line) for line in lines]

    def allowed_signers(self) -> List[str]:
        """
        Transform each Authorized Key into an ALLOWED SIGNERS record

        More information on ALLOWED SIGNERS can be found in the `ssh-keygen(1)`
        manual page.
        """
        return [k.into_allowed_signer(self) for k in self.authorized_keys()]

    def verify_signed_data(self, data: bytes, signature_path: str) -> bool:
        """
        Check whether we have a valid signature for `data` from the current
        GitHub user.

        Parameters:
        - data: the bytes which were signed
        - signature_path: a path to the signature file created by ssh-keygen

        Returns true if the signature matches, false if not.
        """
        with tempfile.NamedTemporaryFile() as allowed_signers_file:
            signers = "\n".join(self.allowed_signers()) + "\n"
            # We write and flush together because we need to know for sure that
            # all these bytes have been written to disk before we try to point
            # ssh-keygen at this file.
            allowed_signers_file.write(bytes(signers, 'utf-8'))
            allowed_signers_file.flush()
            results = subprocess.run([
                'ssh-keygen', '-Y', 'verify',
                '-f', allowed_signers_file.name,  # This file was just flushed.
                '-I', self.username,
                '-n', NAMESPACE,
                '-s', signature_path
            ], input=data, capture_output=True)
            return results.returncode == 0

    def __str__(self) -> str:
        return self.username


@dataclass
class PrivateKey:
    """
    An SSH Private Key for the GitHub user identified by the `profile` object.
    """
    profile: Profile
    path: str

    def sign(self, file: str):
        """
        Use this private key to sign the contents of `file`.

        Parameters:
        - file: the file (on disk) which should be signed

        Upon success, the signature will be stored in `file`.sig.
        """
        subprocess.run([
            'ssh-keygen', '-Y', 'sign',
            '-f', self.path,
            '-n', NAMESPACE,
            file
        ], check=True)


@dataclass
class Signature:
    """
    The output of ssh-keygen -Y sign
    """
    content: str

    @classmethod
    def load(cls, path: str) -> 'Signature':
        """
        Load an SSH signature from a file

        Parameters:
        - path: path to an SSH signature file

        The SSH signature is stored on disk in a format determined by OpenSSH.
        This format is line-oriented, which is tricky to work with in a JSON
        document. As such, we choose to work with a base64-encoded
        representation of this signature instead.
        """
        with open(path) as f:
            raw_text = f.read()
            # Encode the signature bytes file as a Base64 string
            content = str(base64.b64encode(bytes(raw_text, 'utf-8')), 'utf-8')
            return cls(content)

    def dump(self, path: str):
        """
        Write an SSH signature to disk,

        Parameters:
        - path: the path where the SSH signature should be written

        Since the SSH signature in a WMAP file (and in this object) is in
        base64, we need to decode it before writing it to disk so that it
        matches the format which ssh-keygen expects.
        """
        with open(path, 'w') as f:
            decoded = str(base64.b64decode(self.content), 'utf-8')
            f.write(decoded)

    def __str__(self) -> str:
        return self.content


@dataclass
class Message:
    """
    A signed copy of the original content, which can be shared with and
    validated by anyone.
    """
    profile: Profile
    body: bytes
    signature: Signature

    @classmethod
    def from_signed_file(cls, profile: Profile, path: str) -> 'Message':
        """
        Create a Message object from a file and its signature.

        Parameters:
        - profile: the GitHub profile of the user who signed this document
        - path: path to the document which was signed

        Assumptions:
        The document referenced by `path` should have been signed (using wmap)
        prior to calling this method. In particular, an OpenSSH-formatted
        signature file should exist on disk at `path`.sig.
        """
        with open(path, 'rb') as f:
            body = f.read()
        signature = Signature.load(path + ".sig")
        return cls(profile, body, signature)

    @classmethod
    def load(cls, path: str) -> 'Message':
        """
        Load an existing JSON-formatted WMAP message from disk.

        Parameters:
        - path: path to the JSON-formatted WMAP message
        """
        with open(path) as f:
            d = json.load(f)
            profile = Profile(d['profile'])
            signature = Signature(d['signature'])
            body = base64.b64decode(d['body'])
            return cls(profile, body, signature)

    def into_dict(self) -> dict[str, str]:
        """
        Convert this object into a python dictionary, and convert each of its
        fields into their string representation.
        """
        return {
            'profile': str(self.profile),
            'body': str(base64.b64encode(self.body), 'utf-8'),
            'signature': str(self.signature)
        }

    def dump(self, path: str):
        """
        Store this message on disk.

        Parameters:
        - path: path on disk where this JSON-formatted WMAP message should be
          written.
        """
        with open(path, 'w') as f:
            json.dump(self.into_dict(), f)

if __name__ == "__main__":
    main()
