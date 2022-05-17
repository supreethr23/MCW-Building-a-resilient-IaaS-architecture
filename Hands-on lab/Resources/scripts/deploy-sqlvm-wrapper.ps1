param($user, $password, $domain, $dbsource, $scripturl)

Start-Transcript "C:\deploy-sql-wrapper-log.txt"

Write-Output "User $user"
Write-Output "Domain $domain"


# Get the second script
If (Test-Path "D:") {
	$script = "d:\script.ps1"
	$script2 = "d:\script2.ps1"
} else {
	$script = "$env:temp\script.ps1"
	$script2 = "$env:temp\script2.ps1"
}

# Download the required SQL Scripts
powershell -ExecutionPolicy Unrestricted "[Net.ServicePointManager]::SecurityProtocol = 'Tls12'; Invoke-WebRequest -uri '$scripturl/deploy-sqlvm-wrapped.ps1' -OutFile $script"
powershell -ExecutionPolicy Unrestricted "[Net.ServicePointManager]::SecurityProtocol = 'Tls12'; Invoke-WebRequest -uri '$scripturl/deploy-sqlvm-wrapped2.ps1' -OutFile $script2"


# Need to create appropriate credentials, local and domain
Write-Output "Create credential"
$securePwd =  ConvertTo-SecureString $password -AsPlainText -Force
$localUser = $env:COMPUTERNAME + "\" + $user
$domainUser = ($user + "@" + $domain)
Write-Host $domainUser
$localCred = New-Object System.Management.Automation.PSCredential($localUser,$securePwd)
$domainCred = New-Object System.Management.Automation.PSCredential("demouser@contoso.com",$securePwd)

Write-Output "Local Cred"
Write-Output $localCred

# Need to create apprpriate argumentLists
$ArgumentList = @($password, $dbsource)
$ArgumentList2 = $ArgumentList = @($password, $dbsource, $dnsDomain)

Write-Output "Enable remoting and invoke"
Enable-PSRemoting -force
Set-NetFirewallRule -Name "WINRM-HTTP-In-TCP-PUBLIC" -RemoteAddress Any
Invoke-Command -FilePath $script -Credential $localCred -ComputerName $env:COMPUTERNAME -ArgumentList $ArgumentList
Write-Output "Domain Cred"
Write-Output $domainCred
Invoke-Command -FilePath $script2 -Credential $domainCred -ComputerName $env:COMPUTERNAME -ArgumentList $ArgumentList2
Disable-PSRemoting -Force

Stop-Transcript