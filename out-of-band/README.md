# Out-of-Band Infrastructure

## Vultr Accounts
Create two accounts on Vultr.com, one for Out-of-Band infrastructure,
and one for the service itself.

## Domains
Two domains need to be registered, one for the Out-of-Band
infrastructure, and one for the service itself. Configure the NS records
for both of these domains to point to:

* `ns1.vultr.com`
* `ns2.vultr.com`

## Private GitHub Runner
*All of our other actions will be triggered through this machine.
Ingress to other build hosts must originate through this host.*
