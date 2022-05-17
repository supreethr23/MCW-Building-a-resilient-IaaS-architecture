param($password,
    $dbsource,
    $defaultDnsDomain = "contoso.com",
    $defaultDomain = $dnsDomain)

Start-Transcript "C:\deploy-sqlvm-log2.txt"

# The SPNs seem to end up in the wrong containers (COMPUTERNAME) as opposed to Domain user
# This is a bit of a hack to make sure it is straight. 
# See also: https://support.microsoft.com/en-sg/help/811889/how-to-troubleshoot-the-cannot-generate-sspi-context-error-message
Write-Output "Resetting SPNs"

$computer = $env:COMPUTERNAM
$dnsDomain = $env:USERDOMAIN
$user = $env:USERNAME

if ($dnsDomain.Contains(".")) {
	$domain = $dnsDomain.Substring(0,$dnsDomain.IndexOf("."))
}
else{
    $domain = $dnsDomain
}

$spn1 = "MSOLAPSvc.3/" + $computer + "." + $dnsDomain
$spn2 = $domain + "\" + $computer + "$"
SetSPN -s "$spn1" "$spn2"
$spn1 = "MSOLAPSvc.3/" + $computer
SetSPN -s "$spn1" "$spn2"
$spn1 = "MSSQLSvc/" + $computer + "." + $dnsDomain 
SetSPN -d "$spn1" "$spn2"
$spn2 = $domain + "\" + $user
SetSPN -s "$spn1" "$spn2"
$spn1 = "MSSQLSvc/" + $computer + "." + $dnsDomain + ":1433"
$spn2 = $domain + "\" + $computer + "$"
SetSPN -d "$spn1" "$spn2"
$spn2 = $domain + "\" + $user
SetSPN -s "$spn1" "$spn2"

# Disable IE Enhanced Security Configuration
Write-Output "Disable IE Enhanced Security"
$AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
$UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"

New-Item -Path $adminKey -Force
New-Item -Path $UserKey -Force
New-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
New-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0

$HKLM = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\1"
$HKCU = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\1"
Set-ItemProperty -Path $HKLM -Name "1803" -Value 0
Set-ItemProperty -Path $HKCU -Name "1803" -Value 0
$HKLM = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2"
$HKCU = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2"
Set-ItemProperty -Path $HKLM -Name "1803" -Value 0
Set-ItemProperty -Path $HKCU -Name "1803" -Value 0
$HKLM = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\3"
$HKCU = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\3"
Set-ItemProperty -Path $HKLM -Name "1803" -Value 0
Set-ItemProperty -Path $HKCU -Name "1803" -Value 0
$HKLM = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\4"
$HKCU = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\4"
Set-ItemProperty -Path $HKLM -Name "1803" -Value 0
Set-ItemProperty -Path $HKCU -Name "1803" -Value 0
$HKLM = "HKLM:\Software\Microsoft\Internet Explorer\Security"
New-ItemProperty -Path $HKLM -Name "DisableSecuritySettingsCheck" -Value 1 -PropertyType DWORD

Write-Output "All done"

Stop-Transcript