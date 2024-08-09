#!/usr/bin/env python3
import argparse
import base64
import curses
from dataclasses import dataclass
from enum import Enum, auto
import json
import subprocess
import sys
import tempfile
import threading
import time
from typing import List
import os
from urllib import request
import uuid

API_BASE_URL = "https://oe9xunloch.execute-api.us-east-1.amazonaws.com/prod"  # Replace with the actual base URL of the web service
MESSAGE_LIST = []
LATEST_PARENT = ""
NAMESPACE = "wmap@wmap.dev"


def fetch_messages():  # pragma: no cover
    global LATEST_PARENT
    with request.urlopen(f"{API_BASE_URL}/topics/default") as response:
        parent = response.read().decode().rstrip()
    if parent != LATEST_PARENT:
        LATEST_PARENT = parent
        with request.urlopen(f"{API_BASE_URL}/messages/{parent}") as response:
            message = json.loads(response.read().decode())
            interior = json.loads(str(base64.b64decode(message['body']), 'utf-8'))
            MESSAGE_LIST.append(interior['data'])
    return MESSAGE_LIST


def post_message(message):  # pragma: no cover
    profile = "robertdfrench"
    keypath = "/Users/robert/.ssh/id_rsa"
    interior = {}
    interior['topic'] = "default"
    interior['parent'] = LATEST_PARENT
    interior['data'] = message
    with tempfile.NamedTemporaryFile() as f:
        f.write(bytes(json.dumps(interior), 'utf-8'))
        f.flush()
        sign(profile, keypath, f.name)
        post_json_file(f"{API_BASE_URL}/messages", f.name + ".wmap")


def post_json_file(url, file_path):
    # Read the JSON file
    with open(file_path, 'r') as json_file:
        data = json.load(json_file)
    
    # Convert the JSON data to a byte stream
    data_bytes = json.dumps(data).encode('utf-8')

    # Set the request headers
    headers = {
        'Content-Type': 'application/json'
    }

    # Create the request object
    r = request.Request(url, data=data_bytes, headers=headers, method='POST')

    # Send the request and get the response
    with request.urlopen(r) as response:
        return response.read().decode('utf-8')


def sign(username: str, key: str, file: str):  # pragma: no cover
    """
    Sign a file using the specified GitHub username and SSH key.

    This function creates a WMAP-formatted, signed version of the input file.

    Parameters:
    - username: The GitHub username of the file's author
    - key: Path to the SSH private key of the author
    - file: Path to the file being signed

    Output:
    - Creates a new file named '{file}.wmap' containing the signed message.

    Note: The public key corresponding to the private key must be installed on
    the author's GitHub account.
    """
    profile = Profile(username)             # Load *your* github Profile
    private_key = PrivateKey(profile, key)  # Load *your* SSH Private Key
    private_key.sign(file)                  # Sign `file` with your SSH key
    message = Message.from_signed_file(
            profile, file)                  # Load everything into one object
    message.dump(file + ".wmap")            # Write WMAP-formatted msg to disk
    os.remove(file + ".sig")                # Remove temporary sig file

def chat_window(stdscr):  # pragma: no cover
    curses.curs_set(0)  # Hide cursor
    stdscr.nodelay(1)  # Don't block when waiting for input
    stdscr.timeout(1000)  # Refresh every second

    messages_win = curses.newwin(curses.LINES - 3, curses.COLS, 0, 0)
    input_win = curses.newwin(3, curses.COLS, curses.LINES - 3, 0)
    
    input_win.addstr(1, 1, "> ")
    input_win.refresh()
    
    current_input = ""
    messages = []

    def update_messages():
        nonlocal messages
        while True:
            new_messages = fetch_messages()
            if new_messages:
                messages = new_messages
            time.sleep(2)

    # Start a background thread to update messages
    thread = threading.Thread(target=update_messages)
    thread.daemon = True
    thread.start()

    while True:
        messages_win.clear()
        input_win.clear()
        input_win.addstr(1, 1, f"> {current_input}")

        for i, msg in enumerate(messages[-(curses.LINES - 3):]):
            messages_win.addstr(i, 0, msg)

        messages_win.refresh()
        input_win.refresh()

        key = stdscr.getch()
        if key == curses.KEY_RESIZE:
            # Resize windows if terminal size changes
            messages_win.resize(curses.LINES - 3, curses.COLS)
            input_win.resize(3, curses.COLS)
            input_win.mvwin(curses.LINES - 3, 0)
        elif key == ord('\n'):
            if current_input.strip():
                post_message(current_input.strip())
                current_input = ""
        elif key == 27:  # Escape key
            break
        elif key == curses.KEY_BACKSPACE or key == 127:
            current_input = current_input[:-1]
        elif key != -1:
            current_input += chr(key)

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

if __name__ == "__main__":  # pragma: no cover
    curses.wrapper(chat_window)
