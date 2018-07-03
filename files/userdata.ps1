<powershell>
$KBlink= "https://download.microsoft.com/download/F/3/D/F3D9A5A4-75A3-47C8-971E-9D0D09AAF9DC/Windows8.1-KB3065988-v2-x64.msu"
$TempPath="c:\Temp"
if(Test-Path $TempPath){
    wget $KBlink -OutFile "c:\Temp\Windows8.1-KB3065988-v2-x64.msu"
}else{
    md "C:\Temp"
    wget $KBlink -OutFile "c:\Temp\Windows8.1-KB3065988-v2-x64.msu"
}
# Install KB
try{
    $WUSA = "$env:systemroot\SysWOW64\wusa.exe"
    $dotnet35_Install = Start-Process -FilePath $WUSA -ArgumentList "$TempPath\Windows8.1-KB3065988-v2-x64.msu /quiet /norestart" -Wait -PassThru
}catch{
    Write-Host "Error on KB installation"
}
# Install role IIS on 2012R2
try{
    Install-WindowsFeature -Name Web-Server -IncludeAllSubFeature -IncludeManagementTool
}catch{
    Write-Host "Error on IIS deployment"
}
Remove-Item C:\inetpub\wwwroot\* -Confirm:$false -recurse
$str = "${dbhost}"
$strf = $str.substring(0,$str.length -5)
$cofig = @"
$strf
${dbuser}
${dbpass}
"@
$cofig | Out-File C:\inetpub\wwwroot\config.txt
Copy-S3Object -bucket "demo-end2end-ccoe" -key "WindowsDemo.zip" -LocalFile "C:\inetpub\wwwroot\WebApp.zip"
Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([string]$zipfile, [string]$outpath)

    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}
Unzip "C:\inetpub\wwwroot\WebApp.zip" "C:\inetpub\wwwroot\"
Copy-S3Object -bucket "demo-end2end-ccoe" -key "task.ps1" -LocalFile "C:\Temp"
$T = New-JobTrigger -Daily -At "4:00 AM" -DaysInterval 1
Register-ScheduledJob -Name upload-logs -FilePath "C:\Temp\task.ps1" -Trigger $T
</powershell>
