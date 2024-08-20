# Out of Band Infrastructure

## DNS
After the zone is created, we need to go to the registrar to configure
the nameservers. This should stay fixed even when other infrastructure
is created or destroyed, so we handle it as its own layer of
infrastructure.

## Storage
The S3 bucket contains user data, and should not be deleted even if all
other infrastructure is destroyed.
