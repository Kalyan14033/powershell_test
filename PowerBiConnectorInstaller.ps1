param([switch]$Elevated)

function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if ((Test-Admin) -eq $false)  {
    if ($elevated) {
        # tried to elevate, did not work, aborting
    } else {
        Start-Process powershell.exe  -Verb RunAs -ArgumentList ('-noprofile -noexit -ExecutionPolicy Bypass -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
    }
    exit
}

'Start Install'

Push-Location
Set-Location HKLM:
$registryPath=".\Software\Policies\Microsoft\Power BI Desktop"
$downloadFolder = 'C:\Users\'+$env:username+'\Documents\Power BI Desktop\Custom Connectors'
$downloadUrl='https://sdpondemand.manageengine.com/SDPCloud.pqx'

if(-not(Test-Path $registryPath)){

    "Creating registry Path [$registryPath] as it does not exists"

    New-Item -Path .\Software\Policies\Microsoft -Name 'Power BI Desktop'
}


$registryItem=Get-Item  $registryPath
$registryValue=$registryItem.GetValue("TrustedCertificateThumbprints", $null)

if($registryValue -eq $null){

    "Creating new entry and setting thumbPrint 0CFE8E393E639170AEB1AC4CB8928258545FF36C"
    New-ItemProperty -Path $registryPath -Name TrustedCertificateThumbprints -Value 0CFE8E393E639170AEB1AC4CB8928258545FF36C -Type "MultiString"
}

elseif(-not($registryValue -Match "0CFE8E393E639170AEB1AC4CB8928258545FF36C") ){

    "Appending thumbPrint 0CFE8E393E639170AEB1AC4CB8928258545FF36C to existing entry"
    $newValue = $registryValue + "\00CFE8E393E639170AEB1AC4CB8928258545FF36C"
    Set-ItemProperty -Path $registryPath -Name TrustedCertificateThumbprints -Value $newValue -Type "MultiString"
}

else{
    "thumbPrint 0CFE8E393E639170AEB1AC4CB8928258545FF36C already present in existing entry"
}

Pop-Location


if (-not(Test-Path -Path $downloadFolder)){

    "Creating folder [$downloadFolder] as it does not exists"

    New-Item -Path $downloadFolder -ItemType Directory
}

"Downloading the File SDPCloud.pqx"
$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile($downloadUrl,"$downloadFolder\SDPCloud.pqx")
