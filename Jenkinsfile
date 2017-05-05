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
        junit keepLongStdio: true,
              testResults: 'spec/reports/*.xml'
      }
    }
  }
  catch (any) {
    bswHandleError any
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

        // 2nd arg is creds
        docker.withRegistry('https://quay.io', 'quay_io_docker') {
          ruby.rake 'push'
        }
        bswKeepBuild()
        archiveArtifacts artifacts: 'plugins/installed_plugins.txt',
                         excludes: null
      }
      catch (any) {
        bswHandleError any
        throw any
      }
    }
  }
}
