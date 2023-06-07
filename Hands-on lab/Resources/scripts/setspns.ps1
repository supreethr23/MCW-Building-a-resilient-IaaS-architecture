$dnsDomain = "contoso.com"
$computer = $env:COMPUTERNAME
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