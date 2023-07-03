#!/bin/sh

cat << EOF > /etc/msmtprc
defaults
auth on
tls on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile /var/log/msmtp.log
account $SMTP_ACCOUNT
host $SMTP_HOST
port $SMTP_PORT
auth on
user $SMTP_USERNAME
password $SMTP_PASSWORD
from $SMTP_FROM
account default : $SMTP_ACCOUNT
EOF