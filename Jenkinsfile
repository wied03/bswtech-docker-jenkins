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
      def myBuild = getBuild()
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

def handleError() {
  emailext body: "Build failed! ${env.BUILD_URL}",
           recipientProviders: [[$class: 'DevelopersRecipientProvider'], [$class: 'RequesterRecipientProvider']],
           subject: 'Jenkins Docker image build failed!'
}

def getBuild() {
  def job = getJob()
  return job.getBuild(env.BUILD_NUMBER)
}

def getJob() {
  def jobs = jenkins.model.Jenkins.instance.getAllItems(hudson.model.Job)
  for (hudson.model.Job job : jobs) {
    echo "Checking job ${job.fullDisplayName} against ${env.JOB_NAME}"
    if (job.fullDisplayName == env.JOB_NAME) {
      return job
    }
  }
  throw new Exception("Unable to find job ${env.JOB_NAME}")
}
