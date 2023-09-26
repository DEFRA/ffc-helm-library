<#
.SYNOPSIS
Publish Helm library chart to github repo 'Defra/adp-helm-repository'.

.DESCRIPTION
Package Helm library chart.
Publish Helm library chart to github repo 'Defra/adp-helm-repository' and updates index.yaml file in that repo.

.PARAMETER HelmLibraryPath
Helm library folder root path. requires to package helm library into .tgz package.

.PARAMETER ChartVersion
Current Helm library ChartVersion.

.PARAMETER HelmChartRepoPublic
Helm chart publich url. Requires to index.yaml file.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] 
    [string]$HelmLibraryPath,
    [Parameter(Mandatory)] 
    [string]$ChartVersion,
    [Parameter(Mandatory)] 
    [string]$HelmChartRepoPublic,
    [Parameter()]
    [string]$WorkingDirectory = $PWD
)

Set-StrictMode -Version 3.0

[string]$functionName = $MyInvocation.MyCommand
[datetime]$startTime = [datetime]::UtcNow

[int]$exitCode = -1
[bool]$setHostExitCode = (Test-Path -Path ENV:TF_BUILD) -and ($ENV:TF_BUILD -eq "true")
[bool]$enableDebug = (Test-Path -Path ENV:SYSTEM_DEBUG) -and ($ENV:SYSTEM_DEBUG -eq "true")

Set-Variable -Name ErrorActionPreference -Value Continue -scope global
Set-Variable -Name InformationPreference -Value Continue -Scope global

if ($enableDebug) {
    Set-Variable -Name VerbosePreference -Value Continue -Scope global
    Set-Variable -Name DebugPreference -Value Continue -Scope global
}

Write-Host "${functionName} started at $($startTime.ToString('u'))"
Write-Debug "${functionName}:HelmLibraryPath=$HelmLibraryPath"
Write-Debug "${functionName}:ChartVersion=$ChartVersion"
Write-Debug "${functionName}:HelmChartRepoPublic=$HelmChartRepoPublic"
Write-Debug "${functionName}:WorkingDirectory=$WorkingDirectory"

try {

    [System.IO.DirectoryInfo]$moduleDir = Join-Path -Path $WorkingDirectory -ChildPath "scripts/modules/ps-helpers"
    Write-Debug "${functionName}:moduleDir.FullName=$($moduleDir.FullName)"
    Import-Module $moduleDir.FullName -Force

    [string]$helmPackageCommand = "helm package $HelmLibraryPath"
    Write-Host $helmPackageCommand
    Invoke-CommandLine -Command $helmPackageCommand | Out-Null

    [string]$packageName = Split-Path $HelmLibraryPath -Leaf
    [string]$packageNameWithVersion = "$packageName-$ChartVersion.tgz"

    Move-Item -Path $packageNameWithVersion -Destination ../ADPHelmRepository

    Write-Host "Set-Location to ADPHelmRepository"
    Set-Location ../ADPHelmRepository

    [string]$helmIndexCommand = "helm repo index . --url $HelmChartRepoPublic"
    Write-Host $helmIndexCommand
    Invoke-CommandLine -Command $helmIndexCommand | Out-Null
    
    [string]$userEmail = "ado@noemail.com"
    [string]$userName = "Devops"

    [string]$gitUserEmailCommand = "git config user.email $userEmail"
    Write-Host $gitUserEmailCommand
    Invoke-CommandLine -Command $gitUserEmailCommand | Out-Null

    [string]$gitUserNameCommand = "git config user.name $userName"
    Write-Host $gitUserNameCommand
    Invoke-CommandLine -Command $gitUserNameCommand | Out-Null
    
    Write-Host "Push package to adp-helm-repository.."
    
    [string]$gitCheckoutCommand = "git checkout -b main"
    Write-Host $gitCheckoutCommand
    Invoke-CommandLine -Command $gitCheckoutCommand | Out-Null
    
    [string]$gitStagingCommand = "git add $packageNameWithVersion"
    Write-Host $gitStagingCommand
    Invoke-CommandLine -Command $gitStagingCommand | Out-Null

    [string]$commitMessage = "Add new version $ChartVersion"
    [string]$author = "ADO Devops <ado@noemail.com>"
    [string]$gitCommitCommand = "git commit -am '$commitMessage' --author='$author'"
    Write-Host $gitCommitCommand
    Invoke-CommandLine -Command $gitCommitCommand | Out-Null
    
    [string]$gitPushCommand = "git push --set-upstream origin main"
    Write-Host $gitPushCommand
    Invoke-CommandLine -Command $gitPushCommand | Out-Null

    $exitCode = 0
}
catch {
    $exitCode = -2
    Write-Error $_.Exception.ToString()
    throw $_.Exception
}
finally {
    [DateTime]$endTime = [DateTime]::UtcNow
    [Timespan]$duration = $endTime.Subtract($startTime)

    Write-Host "${functionName} finished at $($endTime.ToString('u')) (duration $($duration -f 'g')) with exit code $exitCode"
    if ($setHostExitCode) {
        Write-Debug "${functionName}:Setting host exit code"
        $host.SetShouldExit($exitCode)
    }
    exit $exitCode
}