def majorVersion = '0.1'
def imageVersion = "${majorVersion}.${env.BUILD_NUMBER}"
def rubyVersion = '2.2.5'
def rubyShell = { cmd -> sh "bash --login -c 'rbenv shell ${rubyVersion} && ${cmd}'" }
def rakeCommand = { cmd -> rubyShell("IMAGE_VERSION=${imageVersion} bundle exec rake ${cmd}") }

node('docker.build') {
  try {
    stage 'Checkout'
    checkout([$class: 'GitSCM',
              branches: [[name: '*/master']],
              doGenerateSubmoduleConfigurations: false,
              extensions: [[$class: 'CleanBeforeCheckout']],
              submoduleCfg: [],
              userRemoteConfigs: [[credentialsId: 'bitbucket',
                                   url: 'git@bitbucket.org:bradyw/bswtech-docker-jenkins.git']]])

    stage 'Dependencies'
    rubyShell 'bundle install'

    stage 'Build image'
    rakeCommand 'build'

    stage 'Test'
    // RSpec CI reporter
    env.GENERATE_REPORTS = 'true'
    try {
      rakeCommand 'spec'
      def job = jenkins.model.Jenkins.instance.getItem(env.JOB_NAME)
      def myBuild = job.getBuild(env.BUILD_NUMBER)
      myBuild.keepLog(true)
    }
    finally {
      step([$class: 'JUnitResultArchiver',
            testResults: 'spec/reports/*.xml'])
    }
  }
  catch (any) {
    handleError()
    throw any
  }
}

stage 'Publish Image'
input 'Publish image to quay.io?'
node('docker.build') {
  try {
    // 2nd arg is creds
    docker.withRegistry('https://quay.io', 'quay_io_docker') {
      rakeCommand 'push'
    }
  }
  catch (any) {
    handleError()
    throw any
  }
}

void handleError() {
  emailext body: "Build failed! ${env.BUILD_URL}",
           recipientProviders: [[$class: 'DevelopersRecipientProvider'], [$class: 'RequesterRecipientProvider']],
           subject: 'Jenkins Docker image build failed!'
}
