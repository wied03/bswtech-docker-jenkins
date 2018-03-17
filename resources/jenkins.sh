#! /bin/bash

set -e

# no overwrite
cp -Rvn $JENKINS_REF_DIR/* $JENKINS_HOME

# TODO: DRY, both here and spec helper??
mkdir -p /var/cache/tomcat/work
mkdir -p /var/cache/tomcat/temp

# if `docker run` first argument start with `--` the user is passing jenkins launcher arguments
if [[ $# -lt 1 ]] || [[ "$1" == "--"* ]]; then
  # user.home needs to be explicitly set because we don't have an actual user account, just a UID a and Ivy depends on this
  JAVA_OPTS="${JAVA_OPTS} -Dhudson.remoting.ClassFilter=hudson.plugins.jira.JiraProjectProperty\$DescriptorImpl -DJENKINS_HOME=${JENKINS_HOME} -Duser.home=${JENKINS_HOME} -Dorg.apache.tomcat.util.buf.UDecoder.ALLOW_ENCODED_SLASH=true -Dhudson.PluginManager.className=com.bswtechconsulting.jenkins.ReadOnlyPluginManager" exec /usr/libexec/tomcat/server start
fi

# As argument is not jenkins, assume user want to run his own process, for sample a `bash` shell to explore this image
exec "$@"
