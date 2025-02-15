# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
# WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

<#
    .DESCRIPTION
    Enables Windows Remote Management on Windows builds.
#>

$ErrorActionPreference = "Stop"

# Set network to private
Set-NetConnectionProfile -NetworkCategory Private

# Enable Windows Remote Management in the Windows Firewall.
Write-Output "Enabling Windows Remote Management in the Windows Firewall..."
try {
    $NetworkListManager = [Activator]::CreateInstance([Type]::GetTypeFromCLSID([Guid]"{DCB00C01-570F-4A9B-8D69-199FDBA5723B}"))
    $Connections = $NetworkListManager.GetNetworkConnections()
    $Connections | ForEach-Object { $_.GetNetwork().SetCategory(1) }
} catch {
    Write-Output "Handled for Windows 11"
}

# Set the Windows Remote Management configuration.
Write-Output "Setting the Windows Remote Management configuration..."
try {
    Enable-PSRemoting -Force
    winrm quickconfig -q
    winrm quickconfig -transport:http
    winrm set winrm/config '@{MaxTimeoutms="1800000"}'
    winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="800"}'
    winrm set winrm/config/service '@{AllowUnencrypted="true"}'
    winrm set winrm/config/service/auth '@{Basic="true"}'
    winrm set winrm/config/client/auth '@{Basic="true"}'
    winrm set winrm/config/listener?Address=*+Transport=HTTP '@{Port="5985"}'
} catch {
    Write-Output "Error setting Windows Remote Management Config..."
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