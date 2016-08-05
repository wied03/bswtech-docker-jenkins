#!/bin/bash

set -e

if [ -z "$1" ]
  then
  echo 'Need to supply the Jenkins host volume data directory!'
  exit 1
fi

JENKINS_HOME=$1
ARGS=("$@")

echo 'Run the following commands on the host before starting the container:'
echo "groupadd -g ${JENKINS_GID} ${JENKINS_GROUP}"
echo "useradd -r -d ${JENKINS_HOME} -u ${JENKINS_UID} -g ${JENKINS_GID} -m -s /bin/bash ${JENKINS_USER}"

# Create Container
chroot ${HOST} docker create --name ${NAME} --cap-drop=all --read-only --tmpfs /run --tmpfs /tmp:exec -v ${JENKINS_HOME}:/var/jenkins_home:Z ${ARGS[@]:1} ${IMAGE}

# Install systemd unit file for running container
cp /jenkins_template.service > ${HOST}/etc/systemd/system/${NAME}.service

# Enabled systemd unit file
chroot ${HOST} systemctl enable /etc/systemd/system/${NAME}.service
