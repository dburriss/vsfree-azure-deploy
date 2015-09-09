# from https://gist.github.com/davideicardi/a8247230515177901e57
Param(
    [Parameter(Mandatory = $true)]
    [string]$websiteName,
    [Parameter(Mandatory = $true)]
    [string]$sourceDir,
    [string]$destinationPath = "/site/wwwroot"
    )

# Usage: .\kuduSiteUpload.ps1 -websiteName mySite -sourceDir C:\Temp\mydir

Function d3-KuduUploadDirectory
{
    param( 
	    [string]$siteName = $( throw "Missing required parameter siteName"),
	    [string]$sourcePath = $( throw "Missing required parameter sourcePath"),
	    [string]$destinationPath = $( throw "Missing required parameter destinationPath")
	)

    $zipFile = [System.IO.Path]::GetTempFileName() + ".zip"

    d3-ZipFiles -zipfilename $zipFile -sourcedir $sourcePath

    d3-KuduUploadZip -siteName $siteName -sourceZipFile $zipFile -destinationPath $destinationPath
}

Function d3-KuduUploadZip
{
	param( 
	    [string]$siteName = $( throw "Missing required parameter siteName"),
	    [string]$sourceZipFile = $( throw "Missing required parameter sourceZipFile"),
	    [string]$destinationPath = $( throw "Missing required parameter destinationPath")
	)
	$webSite = Get-AzureWebsite -Name $siteName
    
    $timeOutSec = 600

	$username = $webSite.PublishingUsername
	$password = $webSite.PublishingPassword
	$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username,$password)))

	$baseUrl = "https://" + $siteName + ".scm.azurewebsites.net"
	$apiUrl = d3-JoinParts ($baseUrl, "api/zip", $destinationPath) '/'

	Invoke-RestMethod -Uri $apiUrl -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -Method PUT -InFile $sourceZipFile -ContentType "multipart/form-data" -TimeoutSec $timeOutSec
}

Function d3-JoinParts {
    param ([string[]] $Parts, [string] $Separator = '/')

    # example:
    #  d3-JoinParts ('http://mysite','sub/subsub','/one/two/three') '/'

    $search = '(?<!:)' + [regex]::Escape($Separator) + '+'  #Replace multiples except in front of a colon for URLs.
    $replace = $Separator
    ($Parts | ? {$_ -and $_.Trim().Length}) -join $Separator -replace $search, $replace
}

Function d3-ZipFiles
{
    Param(
		[Parameter(Mandatory = $true)]
		[String]$zipfilename,
		[Parameter(Mandatory = $true)]
		[String]$sourcedir
    )

    Add-Type -Assembly System.IO.Compression.FileSystem
    $compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
    [System.IO.Compression.ZipFile]::CreateFromDirectory($sourcedir, $zipfilename, $compressionLevel, $false)
}

$startTime = Get-Date
d3-KuduUploadDirectory -siteName $websiteName -sourcePath $sourceDir -destinationPath $destinationPath
$finishTime = Get-Date
Write-Host (" Total time used (minutes): {0}" -f ($finishTime - $startTime).TotalMinutes)