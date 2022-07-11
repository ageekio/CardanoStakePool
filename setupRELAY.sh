#!/bin/bash

# Cardano Relay Node setup for v1.35.0

# Variables - CHANGE ME!!

HOSTNAME="relay01"
SSH_PORT="2376"
TIME_PORT="123"
SSH_ADDR="0.0.0.0"
RELAY_ADDR="<RELAY IP HERE>"
ADMIN_USER="<ADMIN USER HERE>"
CNODE_USER="cardano"
SSH_KEY="<YOUR SSH KEY HERE>"

# No need to change beyond this point - but you can if you must :-)

# Enable firewall and allow SSH on non-default port
ufw --force enable
ufw allow $(echo "$SSH_PORT/tcp")
ufw allow $(echo "$TIME_PORT/tcp")
ufw allow from $RELAY_NODE

apt-get install fail2ban chrony -y
cat > /etc/chrony/chrony.conf << EOF
pool time.google.com       iburst minpoll 1 maxpoll 2 maxsources 3
pool ntp.ubuntu.com        iburst minpoll 1 maxpoll 2 maxsources 3
pool us.pool.ntp.org     iburst minpoll 1 maxpoll 2 maxsources 3
keyfile /etc/chrony/chrony.keys
driftfile /var/lib/chrony/chrony.drift
logdir /var/log/chrony
maxupdateskew 5.0
rtcsync
makestep 0.1 -1
EOF

systemctl restart chrony.service


cat > /etc/fail2ban/jail.local << EOF
[sshd]
enabled = true
port = <22 or your random port number>
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
# whitelisted IP addresses
ignoreip = $WHITE_IP
EOF



cat > /etc/ssh/sshd_config << EOF
Port $SSH_PORT
ListenAddress $SSH_ADDR

HostKey /etc/ssh/ssh_host_rsa_key
#HostKey /etc/ssh/ssh_host_dsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

# Logging
SyslogFacility AUTHPRIV
LogLevel INFO

# Authentication:

#LoginGraceTime 2m
PermitRootLogin no
MaxAuthTries 3
MaxSessions 3

PubkeyAuthentication yes
AuthorizedKeysFile      .ssh/authorized_keys

# To disable tunneled clear text passwords, change to no here!
PasswordAuthentication no

# Change to no to disable s/key passwords
ChallengeResponseAuthentication no

# GSSAPI options
GSSAPIAuthentication no
GSSAPICleanupCredentials no
GSSAPIStrictAcceptorCheck no

UsePAM yes
X11Forwarding no
UseDNS no
EOF

systemctl restart sshd.service

cat > /etc/systemd/system/cnode.service << EOF
[Unit]
Description=Cardano Core Node - GEEK
After=syslog.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=20
User=cardano
LimitNOFILE=131072
WorkingDirectory=/opt/cardano
ExecStart=cardano-node run +RTS -N -A16m -qg -qb -RTS --topology /opt/cardano/files/testnet-topology.json --config /opt/cardano/files/testnet-config.json --database-path /opt/cardano/db --socket-path /opt/cardano/db/socket --host-addr 0.0.0.0 --port 6000
KillSignal=SIGINT
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=geek-pool

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable cnode.service

cat > /etc/hostname << EOF
$(echo $HOSTNAME)
EOF

useradd -m -s /bin/bash $ADMIN_USER
usermod -aG sudo $ADMIN_USER
passwd $ADMIN_USER

mkdir /home/io/.ssh
cat > /home/io/.ssh/authorized_keys << EOF
$(echo $SSH_KEY)
EOF

chown -R $(echo "$ADMIN_USER:$ADMIN_USER") /home/io/.ssh

useradd -m -s /bin/bash $CNODE_USER
usermod -aG sudo $CNODE_USER
passwd $CNODE_USER

chown -R $(echo "$CNODE_USER:$CNODE_USER") /opt/cardano

echo "# Check settings before reboot"
echo ""
echo "Machine name: $(hostname)"
echo "$(ufw status)"
echo "SSH address: $(cat /etc/ssh/sshd_config | egrep -i listen) SSH port: $(cat /etc/ssh/sshd_config | egrep -i port)"
