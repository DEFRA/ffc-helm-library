@Library('defra-library@v-8') _

import uk.gov.defra.ffc.Version

def pr = ''
def repoName = ''

node {
  checkout scm

  try {
    stage('Set GitHub status as pending'){
      build.setGithubStatusPending()
    }

    stage('Set PR and version variables') {
      (repoName, pr) = build.getVariables('')
    }

    if (pr != '') {
      stage('Verify version incremented') {
        def currentVersion = sh(returnStdout: true, script:"cat $repoName/Chart.yaml | yq r - version")
        def previousVersion = sh(returnStdout: true, script:"git show origin/master:$repoName/Chart.yaml | yq r - version")
        Version.errorOnNoVersionIncrement(this, previousVersion, currentVersion)
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
