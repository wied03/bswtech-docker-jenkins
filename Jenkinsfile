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

    stage 'Test image'
    // TODO: Put these in slave setup perhaps??
    sh "git clone https://github.com/rbenv/rbenv.git ~/.rbenv"
    sh "echo 'export PATH=\"$HOME/.rbenv/bin:$PATH\"' >> ~/.bash_profile"
    sh "echo 'eval \"$(rbenv init -)\"' >> ~/.bash_profile"
    sh ". ~/.bash_profile"
    sh "git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build"
    sh 'type rbenv'
    sh 'rbenv install 2.2.5'
    sh 'rbenv shell 2.2.5'
    // TODO: End rbenv setup steps
    sh 'bundle install'
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
