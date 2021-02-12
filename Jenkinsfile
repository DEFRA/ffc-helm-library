@Library('defra-library@v-9') _

import uk.gov.defra.ffc.Version

def pr = ''
def repoName = ''
String defaultBranch = 'main'

node {
  try {
    stage('Ensure clean workspace') {
        deleteDir()
      }

      stage('Set default branch') {
        defaultBranch = build.getDefaultBranch(defaultBranch, config.defaultBranch)
      }

      stage('Set environment') {
        environment = config.environment != null ? config.environment : environment
      }

      stage('Checkout source code') {
        build.checkoutSourceCode(defaultBranch)
      }

    stage('Set PR and version variables') {
      (repoName, pr) = build.getVariables('')
    }

    if (pr != '') {
      stage('Verify version incremented') {
        def currentVersion = sh(returnStdout: true, script:"cat $repoName/Chart.yaml | yq r - version").trim()
        def previousVersion = sh(returnStdout: true, script:"git show origin/master:$repoName/Chart.yaml | yq r - version").trim()
        Version.errorOnNoVersionIncrement(this, previousVersion, currentVersion)
      }

      stage('Helm lint') {
        sh("helm lint $repoName")
      }
    }
    else {
      stage('Publish Helm chart') {
        sh("helm package $repoName")

        def currentVersion = sh(returnStdout: true, script:"cat $repoName/Chart.yaml | yq r - version").trim()
        def packageName = "$repoName-${currentVersion}.tgz"
        def helmRepoDir = 'helm-repo'
        sh("rm -fr $helmRepoDir")

        dir("$helmRepoDir") {
          withCredentials([string(credentialsId: 'github-ffcplatform-access-token', variable: 'gitToken')]) {
            git(url: 'https://github.com/DEFRA/ffc-helm-repository.git')
            sh("mv ../$packageName .")
            sh('helm repo index . --url $HELM_CHART_REPO_PUBLIC')
            sh("git add $packageName")
            sh("git commit -am \"Add new version $currentVersion\" --author=\"FFC Jenkins <jenkins@noemail.com>\"")
            sh("git push https://$gitToken@github.com/DEFRA/ffc-helm-repository.git")
          }
          deleteDir()
        }
      }
    }

  } catch(e) {
    notifySlack.buildFailure(e.message, "#generalbuildfailures")
    throw e
  }
}
