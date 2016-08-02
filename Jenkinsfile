def majorVersion = '1.0'
def imageTag = "bswtech/rocker_first:${majorVersion}.${env.BUILD_NUMBER}"

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

    def rubyVersion = '2.2.5'
    def rubyShell = { cmd -> sh "bash --login -c 'rbenv shell ${rubyVersion} && ${cmd}'" }

    stage 'Dependencies'
    rubyShell 'bundle install'

    stage 'Build image'
    def rakeCommand = { cmd -> rubyShell("IMAGE_TAG=${imageTag} bundle exec rake ${cmd}") }
    rakeCommand 'build'

    stage 'Test'
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
  catch (any) {
    handleError()
    throw any
  }
}

stage 'Publish Image'
input 'Publish image'
node('docker.build') {
  docker.image('ruby:2.2.4').inside {
    unstash 'packaged_gem'
    sh 'gem spec *.gem'
    // TODO: Add commands dor deploying GEMs
  }
}

void handleError() {
  emailext body: "Build failed! ${env.BUILD_URL}",
           recipientProviders: [[$class: 'DevelopersRecipientProvider'], [$class: 'RequesterRecipientProvider']],
           subject: 'Jenkins Docker image build failed!'
}
