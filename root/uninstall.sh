#!/bin/bash

set -e

chroot ${HOST} systemctl disable /etc/systemd/system/${NAME}.service
rm -f ${HOST}/etc/systemd/system/${NAME}.service

echo 'Run the following commands on the host to remove user/data'
echo "userdel ${JENKINS_USER}"
