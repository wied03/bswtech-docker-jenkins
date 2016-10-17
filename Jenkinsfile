def rubyShell = { cmd -> sh "bash --login -c 'rbenv shell 2.2.5 && ${cmd}'" }
def rakeCommand = { cmd -> rubyShell("MINOR_VERSION=${env.BUILD_NUMBER} bundle exec rake --trace ${cmd}") }

node('docker.build') {
  // should only need 3 master builds (code will mark published builds as permanent)
  if (env.BRANCH_NAME == 'master') {
    properties([[$class: 'BuildDiscarderProperty',
                 strategy: [$class: 'LogRotator',
                            artifactDaysToKeepStr: '',
                            artifactNumToKeepStr: '',
                            daysToKeepStr: '',
                            numToKeepStr: '3']
                ]])
  }

  try {
    stage('Checkout') {
      checkout scm
    }

    stage('Dependencies') {
      rubyShell 'bundle install'
      // we compile Java code for this image and it's a one off
      sh 'yum install -y java-1.7.0-openjdk-devel-1.7.0.111-2.6.7.2.el7_2 maven'
    }

    stage('Build image') {
      rakeCommand 'build'
    }

    stage('Test') {
      // RSpec CI reporter
      env.GENERATE_REPORTS = 'true'
      try {
        rakeCommand 'spec'
      }
      finally {
        step([$class: 'JUnitResultArchiver',
              testResults: 'spec/reports/*.xml'])
      }
    }
  }
  catch (any) {
    handleError()
    throw any
  }
}

// only allow pushing from master
if (env.BRANCH_NAME == 'master') {
  stage('Publish Image') {
    node('docker.build') {
      try {
        // might be on a different node (filesystem deps)
        rubyShell 'bundle install'
        sh 'yum install -y java-1.7.0-openjdk-devel-1.7.0.111-2.6.7.2.el7_2 maven'

        // 2nd arg is creds
        docker.withRegistry('https://quay.io', 'quay_io_docker') {
          rakeCommand 'push'
        }
        keepBuild()
      }
      catch (any) {
        handleError()
        throw any
      }
    }
  }
}

def handleError() {
  emailext body: "Build failed! ${env.BUILD_URL}",
           recipientProviders: [[$class: 'DevelopersRecipientProvider'],
                                [$class: 'RequesterRecipientProvider']],
           subject: 'Jenkins Docker image build failed!'
}

@NonCPS
def keepBuild() {
  def job = getJob()
  def build = job.getBuild(env.BUILD_NUMBER)
  build.keepLog(true)
}

@NonCPS
def getJob() {
  def jobs = jenkins.model.Jenkins.instance.getAllItems(hudson.model.Job)
  // Groovy complained about using .each
  for (hudson.model.Job job : jobs) {
    if (job.fullName == env.JOB_NAME) {
      return job
    }
  }
  throw new Exception("Unable to find job ${env.JOB_NAME}")
}
