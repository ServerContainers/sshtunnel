# SSH Tunnel Container on debian:stretch (ghcr.io/servercontainers/sshtunnel) [x86 + arm]

it gives you a hardened ssh configuration where you only allow tcp forwarding to specific ports.

Look at the Docker Compose file.

Can have multiple users with thier own custom configurations

It is roughly based on this informations: https://askubuntu.com/questions/48129/how-to-create-a-restricted-ssh-user-for-port-forwarding

## Build & Versions

You can specify `DOCKER_REGISTRY` environment variable (for example `my.registry.tld`)
and use the build script to build the main container and it's variants for _x86_64, arm64 and arm_

You'll find all images tagged like `d11.2-s1.2.1-2.1` which means `d<debian version>-s<openssh-server version (with some esacped chars)>`.
This way you can pin your installation/configuration to a certian version. or easily roll back if you experience any problems
(don't forget to open a issue in that case ;D).

To build a `latest` tag run `./build.sh release`

## Changelogs

* 2024-07-06
    * update to debian `bookworm`
    * fixed build
* 2023-03-20
    * github action to build container
    * implemented ghcr.io as new registry

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
