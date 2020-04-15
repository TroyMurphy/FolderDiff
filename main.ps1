$exportDir = "C:\Users\Troy Murphy\source\repos\FolderDiff\exports\";
$targetDir = "C:\Users\Troy Murphy\source\repos\FolderDiff\target\";

$cachedFileList = "C:\Users\Troy Murphy\source\repos\FolderDiff\cachedFileList.txt";
[string[]]$Excludes = @('*Kyle*', '*parents*');

# Append Nothing to the file to ensure it exists. First email will send full diff of the file. If this is not desired output, populate the file with content Beforehand.
if ((Test-Path $cachedFileList) -eq $false){
	Add-Content $cachedFileList "`r`n";
}

$diffFileName = (Get-Date -Format "yyyy-MMM-dd").ToString() + ".html"
$diffFile = Join-Path (Convert-Path $exportDir) $diffFileName

if (Test-Path $diffFile){
	$confirmation = Read-Host "Log exists. Overwrite? [Y to overwrite, enter to abort]"
	if ($confirmation -notlike 'y') {
		exit;
	}
}

$Header = @"
	<style>
	TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse;}
	TH {border-width: 1px; padding: 3px; border-style: solid; border-color: black; background-color: #6495ED;}
	TD {border-width: 1px; padding: 3px; border-style: solid; border-color: black;}
	</style>
"@

$PreContent = @"
	<h1>Changelog for {0}</h1>
"@ -f (Get-Date -Format "MMMM dd, yyyy")

Function GetListOfFiles {
	return Get-ChildItem -Path $targetDir -Recurse -Exclude $Excludes | %{ 
		$allowed = $true
		foreach ($exclude in $Excludes) { 
			if ((Split-Path $_.FullName -Parent) -ilike $exclude) { 
				$allowed = $false
				break
			}
		}
		if ($allowed) {
			$_
		}
	} `
	| Where-Object {$_.PSIsContainer -eq $false} `
	| Select-Object -ExpandProperty FullName
}

Function GenerateHTMLReport {
	Compare-Object `
	-ReferenceObject (Get-Content $cachedFileList) `
	-DifferenceObject (GetListOfFiles) `
	| Where-Object {$_.InputObject -match '\S'} `
	| ConvertTo-Html `
	-Property `
		@{Label='FileName'; Expression={"<a href='file:///{0}'>{0}</a>" -f ($_.InputObject) }}, `
		@{Label='Change'; Expression={$(If ($_.SideIndicator -eq '=>') {"<span style='color:green'>+ Added</span>"} Else {"<span style='color:red'>- Removed</span>"})}} `
	-Head $Header `
	-PreContent $PreContent 
}

$html= GenerateHTMLReport

Add-Type -AssemblyName System.Web
[System.Web.HttpUtility]::HtmlDecode($html) | Out-File -FilePath $diffFile;

Write-Host "Report Generated"

(GetListOfFiles) | Out-File -FilePath $cachedFileList;

Write-Host "Cache Updated"