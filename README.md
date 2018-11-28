# SSH Tunnel Container on debian:stretch

it gives you a hardened ssh configuration where you only allow tcp forwarding to specific ports.

Look at the Docker Compose file.

Can have multiple users with thier own custom configurations

Test it using:

`ssh -i ~/.ssh/id_rsa -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -N -L 8080:www.bbc.com:80 bob@127.0.0.1 -p 2222`

