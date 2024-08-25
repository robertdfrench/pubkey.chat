# Pubkey.Chat
*You're Already Logged In!*

![](website/social_media_preview.jpg)

[Pubkey.Chat](https://pubkey.chat) is an example of the
[WMAP](https://github.com/robertdfrench/wmap) protocol in action. It is
an IRC-like experience where all outgoing messages are signed with your
SSH key, and all incoming messages are verified against the author's
pubkeys. Every GitHub user's ssh pubkeys are [publicly
available](https://github.com/robertdfrench.keys).

![](website/screengrab.gif)

## Architecture

### Sending and Receiving Messages
Every message is signed with your SSH private key, and then posted in a
public place. Your friends can verify these messages came from you by
checking the signature against your SSH public keys on GitHub. See
[WMAP](https://github.com/robertdfrench/wmap) for more information on
signing and verification.

```mermaid
sequenceDiagram
    participant GitHub
    participant Pubkey.Chat
    participant Alice
    participant Bob
    Alice->>GitHub: Upload SSH Pubkey
    note over Alice: sign message with <br/> SSH Private Key
    Alice->>Pubkey.Chat: POST to TOPIC
    loop Polling
    Bob->>+Pubkey.Chat: GET latest message for TOPIC
    end
    Pubkey.Chat->>-Bob: New Message from Alice
    Bob->>GitHub: GET Alice's SSH Pubkey
    note over Bob: Verify message against <br/> Alice's SSH Pubkey
```

For the sake of keeping the code simple and easy to auditable, the
client polls for new messages using repeated HTTP GET queries.
