#! /bin/bash

set -e

# Git, etc. needs the uid to resolve
export USER_ID=$(id -u)
export GROUP_ID=$(id -g)
echo "Setting up 'jenkins' user to resolve as uid=${USER_ID},gid=${GROUP_ID}"
export LD_PRELOAD=libnss_wrapper.so
export NSS_WRAPPER_PASSWD=/tmp/passwd
ESCAPED_HOME=${JENKINS_HOME//\//\\/}
cat ${JENKINS_APP_DIR}/passwd.template | sed "s/JENKINS_UID/${USER_ID}/" | sed "s/JENKINS_GID/${GROUP_ID}/" | sed "s/JENKINS_HOME/${ESCAPED_HOME}/" > ${NSS_WRAPPER_PASSWD}
export NSS_WRAPPER_GROUP=/etc/group

# no overwrite
cp -Rvn $JENKINS_REF_DIR/* $JENKINS_HOME

# TODO: DRY, both here and spec helper??
mkdir -p /var/cache/tomcat/work
mkdir -p /var/cache/tomcat/temp

# if `docker run` first argument start with `--` the user is passing jenkins launcher arguments
if [[ $# -lt 1 ]] || [[ "$1" == "--"* ]]; then
  JAVA_OPTS="${JAVA_OPTS} -DJENKINS_HOME=${JENKINS_HOME} -Dorg.apache.tomcat.util.buf.UDecoder.ALLOW_ENCODED_SLASH=true -Dhudson.PluginManager.className=com.bswtechconsulting.jenkins.ReadOnlyPluginManager" exec /usr/libexec/tomcat/server start
fi

# As argument is not jenkins, assume user want to run his own process, for sample a `bash` shell to explore this image
exec "$@"
