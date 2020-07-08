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

    pr = ''

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
    else {
      stage('Publish Helm chart') {
        sh("helm package $repoName")

        def currentVersion = sh(returnStdout: true, script:"cat $repoName/Chart.yaml | yq r - version").trim()
        def packageName = "$repoName-${currentVersion}.tgz"
        def helmRepoDir = 'helm-repo'
        sh("rm -fr $helmRepoDir")

        dir("$helmRepoDir") {
          git(credentialsId: 'ffc-jenkins-pipeline-library-deploy-key', url: "git@github.com:DEFRA/ffc-helm-repository.git")
          sh("mv ../$packageName .")
          sh('helm repo index . --url $HELM_CHART_REPO_PUBLIC')
          sh("git add $packageName")
          sh("git commit --author=\"FFC Jenkins <jenkins@noemail.com>\" -am \"Add new package version $currentVersion\"")
          sh("git push origin master")
          deleteDir()
        }
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
