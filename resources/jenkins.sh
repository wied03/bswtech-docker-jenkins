#! /bin/bash

set -e

# no overwrite
cp -Rvn $JENKINS_REF_DIR/* $JENKINS_HOME

# if `docker run` first argument start with `--` the user is passing jenkins launcher arguments
if [[ $# -lt 1 ]] || [[ "$1" == "--"* ]]; then
  eval "JAVA_OPTS=\"${JAVA_OPTS} -DJENKINS_HOME=${JENKINS_HOME} -Dorg.apache.tomcat.util.buf.UDecoder.ALLOW_ENCODED_SLASH=true -Dhudson.PluginManager.className=com.bswtechconsulting.jenkins.ReadOnlyPluginManager\" exec /usr/libexec/tomcat/server start"
fi

# As argument is not jenkins, assume user want to run his own process, for sample a `bash` shell to explore this image
exec "$@"
