
if (!(Get-Module -ListAvailable -Name "Indented.Net.IP")) {
    Install-Module "Indented.Net.IP" -Scope CurrentUser -Confirm:$false -Force
}

$network = vault kv get -format json -mount=go vmware/network | ConvertFrom-Json

$cidr = $network.data.cidr

$exclusions = @()
$exclusions += $($network.data.dns)
$exclusions += $($network.data.gateway)

$build = vault kv get -format json -mount=go build | ConvertFrom-Json
$exclusions += $($build.data.ip)

$docker = vault kv get -format json -mount=go docker | ConvertFrom-Json
$exclusions += $($docker.data.ip)

$vcsa = vault kv get -format json -mount=go vmware/vcsa | ConvertFrom-Json
$exclusions += $($vcsa.data.ip)

$names = vault kv list go/vmware/esx/ | ConvertFrom-Json

foreach ($name in $names) {
    $esx = vault kv get -format json -mount=go vmware/esx/$($name) | ConvertFrom-Json
    $exclusions += $($esx.data.ip)
}

$exclusions = $exclusions | Get-Unique
$networkRange = Get-NetworkRange -IPAddress $($cidr.split('/')[0]) -SubnetMask $($cidr.split('/')[1])

$networkRangeOrg = $networkRange

$start = $networkRange[$network.data.start -1]
$end =  $networkRange[$network.data.end -1]

$ipObjects = @()
foreach ($exclusion in $exclusions) {
    $ipObjects += $networkRange[$exclusion -1]
}

foreach ($ipObject in $ipObjects) {
    $networkRange = $networkRange | Where-Object {$_.IPAddressToString -ne $ipObject.IPAddressToString}
}

$startIndex = $networkRange.IndexOf($start)
$endIndex = $networkRange.IndexOf($end)

$networkRange = $networkRange[$startIndex.. $endIndex]

$indexList = @()
foreach ($networkItem in $networkRange) {
    $indexList += $networkRangeOrg.IndexOf($networkItem) +1
}

return $indexList