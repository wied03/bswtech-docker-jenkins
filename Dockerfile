FROM centos:7.7.1908

# From Rake
ARG JenkinsBinDir=FOOBAR
ARG JavaPackage=FOOBAR
ARG JenkinsVersion=FOOBAR
ARG GitPackage=FOOBAR
ARG UPGRADE_PACKAGES=FOOBAR
# end from Rake

ENV JENKINS_HOME /var/jenkins_home
# from RPM
ENV JENKINS_APP_DIR ${JenkinsBinDir}/app
ENV JENKINS_REF_DIR ${JenkinsBinDir}/ref
ENV JENKINS_PLUGIN_DIR ${JenkinsBinDir}/plugins
ARG JENKINS_WAR_FILE=${JenkinsBinDir}/jenkins.war

COPY jenkins-ci.org.key /tmp

RUN curl http://pkg.jenkins-ci.org/redhat-stable/jenkins.repo -o /etc/yum.repos.d/jenkins.repo \
 && rpm --import /tmp/jenkins-ci.org.key \
 # EPEL needed for tomcat-native
 && yum install -y epel-release \
 && yum install -y ${JavaPackage} jenkins-${JenkinsVersion} ${GitPackage} unzip nss_wrapper \
 && yum update -y ${UPGRADE_PACKAGES} \
 # trading in faster startup for image size
 && unzip ${JENKINS_WAR_FILE} -d ${JENKINS_APP_DIR} \
 && rm ${JENKINS_WAR_FILE} \
 && yum remove -y unzip \
 && yum clean all \
 && yum autoremove -y \
 && rm -rfv /tmp/*

RUN curl -fsSL https://github.com/krallin/tini/releases/download/v0.9.0/tini-static -o /bin/tini \
  && chmod +x /bin/tini \
  # Ensure we do not have a fake tini
  && echo "fa23d1e20732501c3bb8eeeca423c89ac80ed452  /bin/tini" | sha1sum -c -

# Now pre-load our plugins into the image
COPY plugins/rubygems_wrapper/plugins_final $JENKINS_PLUGIN_DIR/
ARG ImageVersion=FOOBAR
RUN mkdir $JENKINS_HOME \
 && mkdir -p $JENKINS_REF_DIR/init.groovy.d \
 # Keep track of version in the footer
 && printf ".jenkins_ver:after {\n        content: \" - I${ImageVersion}\";\n}\n" >> ${JENKINS_APP_DIR}/css/layout-common.css \
 # These cause problems on startup
 && rm -rf ${JENKINS_APP_DIR}/WEB-INF/detached-plugins/*

COPY resources/jenkins.sh /usr/local/bin/
COPY resources/passwd.template $JENKINS_APP_DIR
# Our own plugin manager to deal with pre-loaded plugins
ARG PluginJarPath=FOOBAR
COPY ${PluginJarPath} ${JENKINS_APP_DIR}/WEB-INF/lib/

ENV CASC_JENKINS_CONFIG ${JENKINS_APP_DIR}/casc
COPY resources/casc/* ${CASC_JENKINS_CONFIG}/

VOLUME ["${JENKINS_HOME}"]

EXPOSE 8080

ENTRYPOINT ["/bin/tini", "-v", "--"]
CMD ["/usr/local/bin/jenkins.sh"]
