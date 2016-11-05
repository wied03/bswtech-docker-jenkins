ruby.version = '2.2.5'

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
      ruby.shell 'bundle install'
      // we compile Java code for this image and it's a one off
      sh 'yum install -y java-1.7.0-openjdk-devel-1.7.0.111-2.6.7.2.el7_2 maven'
    }

    stage('Build image') {
      milestone()
      ruby.rake 'build'
      stash 'complete-workspace'
    }

    stage('Test') {
      milestone()
      // RSpec CI reporter
      env.GENERATE_REPORTS = 'true'
      try {
        ruby.rake 'spec'
      }
      finally {
        step([$class: 'JUnitResultArchiver',
              testResults: 'spec/reports/*.xml'])
      }
    }
  }
  catch (any) {
    bswHandleError(any)
    throw any
  }
}

// only allow pushing from master
if (env.BRANCH_NAME == 'master') {
  stage('Publish Image') {
    milestone()

    node('docker.build') {
      try {
        // might be on a different node (filesystem deps)
        unstash 'complete-workspace'
        ruby.shell 'bundle install'
        sh 'yum install -y java-1.7.0-openjdk-devel-1.7.0.111-2.6.7.2.el7_2 maven'

        // 2nd arg is creds
        docker.withRegistry('https://quay.io', 'quay_io_docker') {
          ruby.rake 'push'
        }
        bswKeepBuild()
      }
      catch (any) {
        bswHandleError(any)
        throw any
      }
    }
  }
}
