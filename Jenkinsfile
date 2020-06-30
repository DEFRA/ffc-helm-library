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
    if (pr != '') {
      stage('Verify version incremented') {
        version.verifyFileIncremented(versionFileName)
      }
    }
    else {
      stage('Package Helm Library Chart') {
        
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
