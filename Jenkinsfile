@Library('defra-library@v-8') _

def pr = ''
def repoName = ''
def versionFileName = "VERSION"

node {
  checkout scm

  try {
    stage('Set GitHub status as pending'){
      build.setGithubStatusPending()
    }

    stage('Set PR and version variables') {
      (repoName, pr, versionTag) = build.getVariables(version.getFileVersion(versionFileName))
    }

    stage('test') {
      sh("cat $repoName/Chart.yaml | yq r - version")
    }

    if (pr != '') {
      stage('Verify version incremented') {
        version.verifyFileIncremented(versionFileName)
      }

      stage('Helm lint') { 
        sh("helm lint $repoName")
      }
    }
    

    stage('Set GitHub status as success'){
      build.setGithubStatusSuccess()
    }
  } catch(e) {
    build.setGithubStatusFailure(e.message)
    notifySlack.buildFailure(e.message, "#generalbuildfailures")
    throw e
  }
}
