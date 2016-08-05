#!/bin/bash

set -e

SYSTEMD_FILE=/etc/systemd/system/${NAME}.service
echo "Disabling systemd service ${SYSTEMD_FILE}"
chroot ${HOST} systemctl disable ${SYSTEMD_FILE}
echo 'Removing systemd service'
rm -f ${HOST}${SYSTEMD_FILE}

echo 'Uninstall complete'
echo 'Run the following commands on the host to remove user/data'
echo "userdel ${JENKINS_USER}"
