@Library('defra-library@v-9') _

import uk.gov.defra.ffc.Version

def pr = ''
def repoName = ''
String defaultBranch = 'master'

node {
  try {
    stage('Ensure clean workspace') {
        deleteDir()
    }

      stage('Checkout source code') {
        build.checkoutSourceCode(defaultBranch)
      }

    stage('Set PR and version variables') {
      (repoName, pr) = build.getVariables('', defaultBranch)
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

      stage('Publish Beta Helm chart') {
        def currentVersion = sh(returnStdout: true, script:"cat $repoName/Chart.yaml | yq r - version").trim()
        // sh("yq e -i '.version = \"${currentVersion}-beta\"' $repoName/Chart.yaml")
        sh("sed -i 's/version: ${currentVersion}/version: ${currentVersion}-beta/g' $repoName/Chart.yaml")
        sh("helm package $repoName")

        def packageName = "$repoName-${currentVersion}-beta.tgz"
        def helmRepoDir = 'helm-repo'
        sh("rm -fr $helmRepoDir")

        dir("$helmRepoDir") {
          withCredentials([string(credentialsId: 'github-ffcplatform-access-token', variable: 'gitToken')]) {
            git(url: 'https://github.com/DEFRA/ffc-helm-repository.git')
            sh("mv ../$packageName .")
            sh('helm repo index . --url $HELM_CHART_REPO_PUBLIC')
            sh("git add $packageName")
            sh("git commit -am \"Add new version $currentVersion-beta\" --author=\"FFC Jenkins <jenkins@noemail.com>\"")
            sh("git push https://$gitToken@github.com/DEFRA/ffc-helm-repository.git")
          }
          deleteDir()
        }
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
  } catch (e) {
    notifySlack.buildFailure(e.message, '#generalbuildfailures')
    throw e
  }
}
