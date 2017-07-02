#! /bin/bash

set -e

# Copy files from /usr/share/jenkins/ref into $JENKINS_HOME
# So the initial JENKINS-HOME is set with expected content.
# Don't override, as this is just a reference setup, and use from UI
# can then change this, upgrade plugins, etc.
copy_reference_file() {
  f="${1%/}"
  b="${f%.override}"
  echo "$f" >> "$COPY_REFERENCE_FILE_LOG"
  rel="${b:23}"
  dir=$(dirname "${b}")
  echo " $f -> $rel" >> "$COPY_REFERENCE_FILE_LOG"
  if [[ ! -e $JENKINS_HOME/${rel} || $f = *.override ]]
  then
    echo "copy $rel to JENKINS_HOME" >> "$COPY_REFERENCE_FILE_LOG"
    mkdir -p "$JENKINS_HOME/${dir:23}"
    cp -r "${f}" "$JENKINS_HOME/${rel}";
  fi;
}

export -f copy_reference_file
touch "${COPY_REFERENCE_FILE_LOG}" || (echo "Can not write to ${COPY_REFERENCE_FILE_LOG}. Wrong volume permissions?" && exit 1)
echo "--- Copying files at $(date)" >> "$COPY_REFERENCE_FILE_LOG"
find "${JENKINS_REF_DIR}/" -type f -exec bash -c "copy_reference_file '{}'" \;

# if `docker run` first argument start with `--` the user is passing jenkins launcher arguments
if [[ $# -lt 1 ]] || [[ "$1" == "--"* ]]; then
  eval "JAVA_OPTS=\"${JAVA_OPTS} -DJENKINS_HOME=${JENKINS_HOME} -Dorg.apache.tomcat.util.buf.UDecoder.ALLOW_ENCODED_SLASH=true -Dhudson.PluginManager.className=com.bswtechconsulting.jenkins.ReadOnlyPluginManager\" exec /usr/libexec/tomcat/server start"
fi

# As argument is not jenkins, assume user want to run his own process, for sample a `bash` shell to explore this image
exec "$@"
