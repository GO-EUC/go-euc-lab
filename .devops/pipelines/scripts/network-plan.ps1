[CmdletBinding()]
param(
    [ValidateSet("vmware", "nutanix")]
    [string]$Platform = "vmware"
)
if (!(Get-Module -ListAvailable -Name "Indented.Net.IP")) {
    Install-Module "Indented.Net.IP" -Scope CurrentUser -Confirm:$false -Force
}

$networkPath = if ($Platform -eq "nutanix") { "nutanix/network" } else { "vmware/network" }
$network = vault kv get -format json -mount=go $networkPath | ConvertFrom-Json

$cidr = $network.data.cidr

$exclusions = @()
$exclusions += $($network.data.dns)
$exclusions += $($network.data.gateway)

$build = vault kv get -format json -mount=go build | ConvertFrom-Json
$exclusions += $($build.data.ip)

$docker = vault kv get -format json -mount=go docker | ConvertFrom-Json
$exclusions += $($docker.data.ip)

if ($Platform -eq "vmware") {
    $vcsa = vault kv get -format json -mount=go vmware/vcsa | ConvertFrom-Json
    $exclusions += $($vcsa.data.ip)

    $names = vault kv list go/vmware/esx/ | ConvertFrom-Json

    foreach ($name in $names) {
        $esx = vault kv get -format json -mount=go vmware/esx/$($name) | ConvertFrom-Json
        $exclusions += $($esx.data.ip)
    }
}

$exclusions = $exclusions | Get-Unique
$networkRange = Get-NetworkRange -IPAddress $($cidr.split('/')[0]) -SubnetMask $($cidr.split('/')[1])

$networkRangeOrg = $networkRange

$start = $networkRange[$network.data.start -1]
$end =  $networkRange[$network.data.end -1]

$ipObjects = @()
foreach ($exclusion in $exclusions) {
    if ($exclusion -is [string] -and $exclusion -match '^\d{1,3}(\.\d{1,3}){3}$') {
        $ipObjects += $networkRange | Where-Object { $_.IPAddressToString -eq $exclusion }
    } else {
        $ipObjects += $networkRange[$exclusion -1]
    }
}

foreach ($ipObject in $ipObjects) {
    $networkRange = $networkRange | Where-Object {$_.IPAddressToString -ne $ipObject.IPAddressToString}
}

$startIndex = $networkRange.IndexOf($start)
$endIndex = $networkRange.IndexOf($end)

# A start/end that collides with an exclusion (gateway, DNS, build, docker)
# is no longer in the filtered range; IndexOf then returns -1 and the range
# operator would silently wrap around to the end of the subnet (a DC at
# .254 instead of .2). Fail loudly instead.
if ($startIndex -lt 0 -or $endIndex -lt 0) {
    throw "network start/end (offsets $($network.data.start)/$($network.data.end)) collide with an excluded address (gateway, DNS, build, or docker). Adjust the network range in the settings/Vault."
}

$networkRange = $networkRange[$startIndex.. $endIndex]

$indexList = @()
foreach ($networkItem in $networkRange) {
    $indexList += $networkRangeOrg.IndexOf($networkItem) +1
}

return $indexList