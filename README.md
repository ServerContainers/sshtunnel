# SSH Tunnel Container on debian:stretch

it gives you a hardened ssh configuration where you only allow tcp forwarding to specific ports.

Look at the Docker Compose file.

Can have multiple users with thier own custom configurations

## Environment Variables

- `USER_<username>`
    - takes ssh public key as argument
    - add a new user and authorize public key
    - e.g. `USER_bob: 'ssh-rsa AAAAB3...your.ssh.public.key.here... bob@macbook'`

- `PERMIT_OPEN_<username>_<permissionname>`
    - takes a sshd `PermitOpen` configuration option as value
    - e.g. `PERMIT_OPEN_bob_bbchttp: 'www.bbc.com:80'`

_all values are able to use multiple values_


## Establish Port Forwarding using SSH Client

```
ssh -i ~/.ssh/id_rsa -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -N -L 8080:www.bbc.com:80 bob@127.0.0.1 -p 2222
```

_if you want the command to recover server disconnects/downtimes etc. just encapsulate it whithin `while true; do command_from_above; sleep 1; done`_
