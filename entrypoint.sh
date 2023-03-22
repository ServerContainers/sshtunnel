#!/bin/sh

cat <<EOF
################################################################################

Welcome to the ghcr.io/servercontainers/sshtunnel

################################################################################

You'll find this container sourcecode here:

    https://github.com/ServerContainers/sshtunnel

The container repository will be updated regularly.

################################################################################


EOF

if [ ! -e '/initialized' ]; then
touch '/initialized'

echo ">> harden ssh config"
sed -i 's/.*PermitRootLogin.*/PermitRootLogin no/g' /etc/ssh/sshd_config
sed -i 's/.*PasswordAuthentication.*/PasswordAuthentication no/g' /etc/ssh/sshd_config
sed -i 's/.*X11Forwarding.*/X11Forwarding no/g' /etc/ssh/sshd_config

echo ">> add users"
env | grep '^USER_' | while read I_ACCOUNT
do
    ACCOUNT_NAME=$(echo "$I_ACCOUNT" | cut -d'=' -f1 | sed 's/USER_//g' | tr '[:upper:]' '[:lower:]')
    ACCOUNT_PUB_KEY=$(echo "$I_ACCOUNT" | sed 's/^[^=]*=//g')

echo "  >> create account: $ACCOUNT_NAME"

useradd -m -s /bin/false "$ACCOUNT_NAME"
mkdir -p "/home/$ACCOUNT_NAME/.ssh"
echo "$ACCOUNT_PUB_KEY" > "/home/$ACCOUNT_NAME/.ssh/authorized_keys"
chown "$ACCOUNT_NAME" -R "/home/$ACCOUNT_NAME/.ssh"
chmod 700 "/home/$ACCOUNT_NAME/.ssh"
chmod 600 "/home/$ACCOUNT_NAME/.ssh/authorized_keys"


echo "    >> add ssh config"

echo 'Match User '"$ACCOUNT_NAME"'
   AllowTcpForwarding yes
   X11Forwarding no
   PermitTunnel no
   GatewayPorts no
   AllowAgentForwarding no
   ForceCommand echo "This Account can only be used for SSH Port Forwarding"
' >> /etc/ssh/sshd_config

env | grep '^'$(echo "$I_ACCOUNT" | sed 's/USER_/PERMIT_OPEN_/g' | sed 's/=.*//g') | while read PERMIT_OPEN_RAW
do
   PERMIT_OPEN=$(echo "$PERMIT_OPEN_RAW" | sed 's/^[^=]*=//g')
   echo "      PermitOpen $PERMIT_OPEN"
   echo "   PermitOpen $PERMIT_OPEN" >> /etc/ssh/sshd_config
done

done

fi

##
# CMD
##
echo ">> CMD: exec docker CMD"
echo "$@"
exec "$@"
