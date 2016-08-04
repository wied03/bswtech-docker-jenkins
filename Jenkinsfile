def majorVersion = '0.1'
def imageVersion = "${majorVersion}.${env.BUILD_NUMBER}"
def rubyShell = { cmd -> sh "bash --login -c 'rbenv shell 2.2.5 && ${cmd}'" }
def rakeCommand = { cmd -> rubyShell("IMAGE_VERSION=${imageVersion} bundle exec rake --trace ${cmd}") }

node('docker.build') {
  try {
    stage 'Checkout'
    checkout scm

    stage 'Dependencies'
    rubyShell 'bundle install'

    stage 'Build image'
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

// only allow pushing from master
if (env.BRANCH_NAME == 'master') {
  stage 'Publish Image'
  input 'Publish image to quay.io?'
  node('docker.build') {
    try {
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

def handleError() {
  emailext body: "Build failed! ${env.BUILD_URL}",
           recipientProviders: [[$class: 'DevelopersRecipientProvider'],
                                [$class: 'RequesterRecipientProvider']],
           subject: 'Jenkins Docker image build failed!'
}

def keepBuild() {
  def job = getJob()
  def build = job.getBuild(env.BUILD_NUMBER)
  build.keepLog(true)
}

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
