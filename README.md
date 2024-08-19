# Pubkey.Chat
*You're Already Logged In!*

![](website/social_media_preview.jpg)

[Pubkey.Chat](https://pubkey.chat) is an example of the
[WMAP](https://github.com/robertdfrench/wmap) protocol in action. It is
an IRC-like experience where all outgoing messages are signed with your
SSH key, and all incoming messages are verified against the author's
pubkeys. Every GitHub user's ssh pubkeys are [publicly
available](https://github.com/robertdfrench.keys).

## Architecture

### Validating Messages
Every message is signed with your SSH private key, and then posted in a
public place. Your friends can verify these messages came from you by
checking the signature against your SSH public keys on GitHub.

```mermaid
flowchart TD
    subgraph Alice's Chat Client
        MT('Hello, Bob!')
        AKP(SSH KeyPair)
        ASM(Signed Message)
    end

    AGH(github.com/alice.keys)

    ASM --> PSM[pubkey.chat/messages/abc123]

    subgraph Bob's Chat Client
        VM["'Hello, Bob!' <br/> (Verified from Alice)"]
    end
    
    MT --> ASM
    AKP -->|pubkey| AGH
    AKP -->ASM
    PSM --> VM
    AGH --> VM
```
