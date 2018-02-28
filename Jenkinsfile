// should only need 3 master builds (code will mark published builds as permanent)
if (env.BRANCH_NAME == 'master') {
  properties([[$class: 'BuildDiscarderProperty',
               strategy: [$class: 'LogRotator',
                          artifactDaysToKeepStr: '',
                          artifactNumToKeepStr: '',
                          daysToKeepStr: '',
                          numToKeepStr: '3']
              ],
              parameters([string(defaultValue: '',
                                 description: 'Base Docker image version',
                                 name: 'DOCKER_BASE_VERSION')])])
}
else {
  // build numbers are not unique across branches
  env.BUILD_NUMBER = "${env.BRANCH_NAME}.${env.BUILD_NUMBER}"
}

if (params.DOCKER_BASE_VERSION) {
    env.DOCKER_BASE_VERSION = params.DOCKER_BASE_VERSION
}

def furyRepo = 'https://repo.fury.io/wied03/'
def furyCredentialId = 'gemfury_key'

node('docker.build') {
  try {
    stage('Checkout') {
      checkout([
        $class: 'GitSCM',
        branches: scm.branches,
        extensions: scm.extensions + [[$class: 'CleanCheckout']],
        userRemoteConfigs: scm.userRemoteConfigs
      ])
    }

    stage('Dependencies') {
      ruby.with_gem_credentials(furyRepo, furyCredentialId) {
        ruby.dependencies()
      }
      // easier to see what Docker tag this build is for
      // true,true = quiet, return stdout
      currentBuild.description = ruby.rake('dump_version', true, true)
    }

    stage('Build image') {
      milestone()
      ruby.with_gem_credentials(furyRepo, furyCredentialId) {
        ruby.rake 'build'
      }
    }

    stage('Test') {
      milestone()
      // RSpec CI reporter
      env.GENERATE_REPORTS = 'true'
      env.HTML_REPORT_PATH = 'spec/reports/html'
      env.JUNIT_REPORT_PATH = 'spec/reports/xml'
      try {
        ruby.rake 'spec'
      }
      finally {
        junit keepLongStdio: true,
              testResults: new File(env.JUNIT_REPORT_PATH, '*.xml')
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
        ruby.with_gem_credentials(furyRepo, furyCredentialId) {
          ruby.dependencies()
        }

        // 2nd arg is creds
        docker.withRegistry('https://quay.io', 'quay_io_docker') {
          ruby.rake 'push'
        }
        bswKeepBuild()
        archiveArtifacts artifacts: 'plugins/Gemfile.lock',
                         excludes: null
      }
      catch (any) {
        bswHandleError any
        throw any
      }
    }
  }
}
