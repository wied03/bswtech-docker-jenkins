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

    stage 'Test dependencies'
    // TODO: rbenv is not being found (look at how we do it in TeamCity)
    // TODO: Add a .ruby-version
    sh 'bash -c "rbenv shell 2.2.5 && ruby -v && bundle install"'

    stage 'Test image'
    sh 'bundle exec rake'
  }
  catch (any) {
    handleError()
    throw any
  }
}

stage 'Deploy Image'
input 'Release GEM?'
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
