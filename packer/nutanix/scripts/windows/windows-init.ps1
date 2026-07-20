# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
# WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

<#
    .DESCRIPTION
    Enables Windows Remote Management on Windows builds.
#>

$ErrorActionPreference = "Stop"

# Set the network profile to Private. WinRM refuses to configure on Public
# networks and its firewall rule is scoped to the local subnet. At first logon
# the adapter is often still in the "Identifying..." state where
# Set-NetConnectionProfile throws, so retry before falling back to the registry.
Write-Output "Setting the network connection profile to Private..."
$profileSet = $false
for ($attempt = 1; $attempt -le 10; $attempt++) {
    try {
        Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private
        $profileSet = $true
        break
    } catch {
        Write-Output "Network profile not ready yet (attempt $attempt): $($_.Exception.Message)"
        Start-Sleep -Seconds 10
    }
}
if (!$profileSet) {
    # Force every known network profile to Private (Category 1) via the registry.
    Write-Output "Falling back to setting the network category through the registry..."
    Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles" -ErrorAction SilentlyContinue |
        ForEach-Object { Set-ItemProperty -Path $_.PSPath -Name Category -Value 1 }
}

# Enable Windows Remote Management in the Windows Firewall.
Write-Output "Enabling Windows Remote Management in the Windows Firewall..."
try {
    $NetworkListManager = [Activator]::CreateInstance([Type]::GetTypeFromCLSID([Guid]"{DCB00C01-570F-4A9B-8D69-199FDBA5723B}"))
    $Connections = $NetworkListManager.GetNetworkConnections()
    $Connections | ForEach-Object { $_.GetNetwork().SetCategory(1) }
} catch {
    Write-Output "Handled for Windows 11"
}

# Set the Windows Remote Management configuration. SkipNetworkProfileCheck
# keeps this working even if a connection is still categorized as Public.
# Each setting is applied independently: `winrm quickconfig` fails outright on
# Public networks, and a single try/catch around the whole block used to skip
# the Basic-auth settings Packer depends on when that happened.
Write-Output "Setting the Windows Remote Management configuration..."
try {
    Enable-PSRemoting -SkipNetworkProfileCheck -Force
} catch {
    Write-Output "Enable-PSRemoting failed: $($_.Exception.Message)"
}
$winrmSettings = @(
    @("winrm/config", '@{MaxTimeoutms="1800000"}'),
    @("winrm/config/winrs", '@{MaxMemoryPerShellMB="800"}'),
    @("winrm/config/service", '@{AllowUnencrypted="true"}'),
    @("winrm/config/service/auth", '@{Basic="true"}'),
    @("winrm/config/client/auth", '@{Basic="true"}'),
    @("winrm/config/listener?Address=*+Transport=HTTP", '@{Port="5985"}')
)
foreach ($setting in $winrmSettings) {
    try {
        winrm set $setting[0] $setting[1] | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "winrm set exited with $LASTEXITCODE" }
    } catch {
        Write-Output "Failed to apply $($setting[0]): $($_.Exception.Message)"
    }
}


# Allow Windows Remote Management in the Windows Firewall.
Write-Output "Allowing Windows Remote Management in the Windows Firewall..."
try {
    netsh advfirewall firewall set rule group="Windows Remote Administration" new enable=yes
    netsh advfirewall firewall set rule name="Windows Remote Management (HTTP-In)" new enable=yes action=allow
} catch {
    Write-Output "Error configuring the Firewall"
}


# Restart Windows Remote Management service.
Write-Output "Restarting Windows Remote Management service..."
try {
    Set-Service winrm -startuptype "auto"
    Restart-Service winrm
} catch {
    Write-Output "Failed to restart service"
}