FROM centos:7.7.1908

# From Rake
ARG JenkinsBinDir=FOOBAR
ARG JavaPackage=FOOBAR
ARG JenkinsVersion=FOOBAR
ARG GitPackage=FOOBAR
ARG ImageVersion=FOOBAR
ARG PluginHash=FOOBAR
ARG ResourcesHash=FOOBAR
ARG PluginJarPath=FOOBAR
ARG UPGRADE_PACKAGES=FOOBAR
# end from Rake

ENV JENKINS_HOME /var/jenkins_home
ENV JENKINS_SLAVE_AGENT_PORT 50000
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
 && yum remove -y unzip \
 && yum clean all \
 && yum autoremove -y \
 && rm -rfv /tmp/*

# Now pre-load our plugins into the image
COPY plugins/rubygems_wrapper/plugins_final $JENKINS_PLUGIN_DIR/

RUN mkdir $JENKINS_HOME \
 && mkdir -p $JENKINS_REF_DIR/init.groovy.d \
 # Keep track of version in the footer
 && printf ".jenkins_ver:after {\n        content: \" - I${ImageVersion}\";\n}\n" >> ${JENKINS_APP_DIR}/css/layout-common.css \
 # These cause problems on startup
 && rm -rf ${JENKINS_APP_DIR}/WEB-INF/detached-plugins/*

COPY resources/jenkins.sh /usr/local/bin/
COPY resources/passwd.template $JENKINS_APP_DIR
# Our own plugin manager to deal with pre-loaded plugins
COPY ${PluginJarPath} ${JENKINS_APP_DIR}/WEB-INF/lib/
COPY resources/init.groovy $JENKINS_REF_DIR/init.groovy.d/tcp-slave-agent-port.groovy

VOLUME ["${JENKINS_HOME}"]

EXPOSE 8080

CMD ["/usr/local/bin/jenkins.sh"]
