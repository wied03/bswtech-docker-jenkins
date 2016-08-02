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

    stage 'Build image'
    sh 'rocker build'

    def rubyVersion = '2.2.5'
    def rubyShell = { cmd -> sh "bash --login -c 'rbenv shell ${rubyVersion} && ${cmd}'" }
    stage 'Dependencies'
    rubyShell 'ruby -v'
    rubyShell 'bundle install'

    stage 'Test'
    // RSpec CI reporter
    env.GENERATE_REPORTS = 'true'
    try {
      rubyShell 'bundle exec rake'
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
