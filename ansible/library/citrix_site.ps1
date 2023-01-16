#Requires -Module Ansible.ModuleUtils.Legacy
#Requires -Module Ansible.ModuleUtils.Backup

Set-StrictMode -Version 2

function Start-DatabaseQuery() {
    param (
        [Parameter(Mandatory=$true)]
        [string]$connection,

        [Parameter(Mandatory=$true)]
        [string]$query
    )

    $sql = New-Object System.Data.SqlClient.SqlConnection
    $sql.ConnectionString = $connection
    $sqlCommand = $sql.CreateCommand()
    $sqlCommand.CommandText = $query

    $sqlResult = New-Object "System.Data.DataTable"
    $sql.Open()
    $sqlResult.Load($sqlCommand.ExecuteReader())

    $sql.Close()
    return $sqlResult
}

function Get-Database {
    param (
        [Parameter(Mandatory=$true)]
        [string]$dbServer,

        [Parameter(Mandatory=$true)]
        [int]$dbPort
    )

    $query = "SELECT name FROM master.dbo.sysdatabases"
    $connectionString = "Server=$dbServer,$dbPort;Integrated Security=True;"

    $databases = Start-DatabaseQuery -connection $connectionString -query $query

    return $databases
}

function Get-DatabaseVersion {
    param (
        [Parameter(Mandatory=$true)]
        [string]$dbServer,

        [Parameter(Mandatory=$true)]
        [int]$dbPort,

        [Parameter(Mandatory=$true)]
        [string]$dbName
    )

    $query = "SELECT [ProductVersion] FROM [ConfigurationSchema].[Site]"
    $connectionString = "Server=$dbServer,$dbPort;Database=$dbName;Integrated Security=True;"

    $queryElements = Start-DatabaseQuery -connection $connectionString -query $query
    foreach ($element in $queryElements) {
        $version = [string]$element.Productversion
    }

    return $version
}

function Get-DatabaseMachine {
    param (
        [Parameter(Mandatory=$true)]
        [string]$dbServer,

        [Parameter(Mandatory=$true)]
        [int]$dbPort,

        [Parameter(Mandatory=$true)]
        [string]$dbName
    )

    $query ="SELECT [MachineName] FROM [ConfigurationSchema].[Services]"
    $connectionString = "Server=$dbServer,$dbPort;Database=$dbName;Integrated Security=True;"

    $machines = Start-DatabaseQuery -connection $connectionString -query $query

    return $machines
}

function Start-DropDatabase {
    param (
        [Parameter(Mandatory=$true)]
        [string]$dbServer,

        [Parameter(Mandatory=$true)]
        [int]$dbPort,

        [Parameter(Mandatory=$true)]
        [string]$dbName
    )

    $query = "IF EXISTS (SELECT name FROM master.dbo.sysdatabases WHERE name =`'$dbName`') `
    BEGIN `
        ALTER DATABASE [$dbName] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; `
        DROP DATABASE [$dbName]; `
    END;"
    $connectionString = "Server=$dbServer,$dbPort;Integrated Security=True;"

    $drop = Start-DatabaseQuery -connection $connectionString -query $query

    return $drop
}

$params = Parse-Args $args -supports_check_mode $false

$debug_level = Get-AnsibleParam -obj $params -name "_ansible_verbosity" -type "int"
$debug = $debug_level -gt 2

$siteName = Get-AnsibleParam $params "name" -type "str" -FailIfEmpty $true
$databaseServer = Get-AnsibleParam $params "db_server" -type "str" -FailIfEmpty $true
$databaseServerPort = Get-AnsibleParam $params "db_port" -type "str" -FailIfEmpty $true
$databaseNameSite = Get-AnsibleParam $params "db_site" -type "str" -Default "CTX_GO_Site"
$databaseNameLogging = Get-AnsibleParam $params "db_log" -type "str" -Default "CTX_GO_Log"
$databaseNameMonitoring = Get-AnsibleParam $params "db_mon" -type "str" -Default "CTX_GO_Mon"
$adminGroup = Get-AnsibleParam $params "admin_group" -type "str" -FailIfEmpty $true
$role = Get-AnsibleParam $params "admin_role" -type "str" -Default "Full Administrator"
$scope = Get-AnsibleParam $params "admin_scope" -type "str" -Default "All"
$groomingDays = Get-AnsibleParam $params "grooming_days" -type "int" -Default 365
$state = Get-AnsibleParam $params "state" -type "str" -Default "present"

$result = @{
    changed = $false
}

$databases = @()
$databases += [PSCustomObject]@{
    Type = "Site"
    Name = $databaseNameSite
    Created = $false
}

$databases += [PSCustomObject]@{
    Type = "Logging"
    Name = $databaseNameLogging
    Created = $false
}

$databases += [PSCustomObject]@{
    Type = "Monitor"
    Name = $databaseNameMonitoring
    Created = $false
}

try {
    Import-Module Citrix.XenDesktop.Admin
} catch {
    Fail-Json $result "Failed to import the required PowerShell module. Error: $($_)"
}


if ($state -eq "absent") {

    $dropDb = $true

    # Collect all the current databases of the SQL server
    $currentDatabases = Get-Database -dbServer $databaseServer -dbPort $databaseServerPort

    # Check if the required databases are allready there
    foreach ($db in $currentDatabases) {
        if ($databases.Name -match $db.Name) {
            $dbUpdate = $databases | Where-Object { $_.Name -eq $db.Name }
            $index = $databases.IndexOf($dbUpdate)
            $databases[$index].Created = $true
        }
    }

    if ($databases.Created -eq $true) {
        $machines = Get-DatabaseMachine -dbServer $databaseServer -dbPort $databaseServerPort -dbName $databaseNameSite

        if ($machines.MachineName -ne $env:ComputerName -and [string]::IsNullOrEmpty($machines.MachineName) -eq $false) {
            $dropDb = $false
        }
    }

    $connectionArray = @()
    $connectionArray += "AcctDBConnection"
    $connectionArray += "AnalyticsDBConnection"
    $connectionArray += "AppLibDBConnection"
    $connectionArray += "BrokerDBConnection"
    $connectionArray += "EnvTestDBConnection"
    $connectionArray += "HypDBConnection"
    $connectionArray += "MonitorDBConnection"
    $connectionArray += "OrchDBConnection"
    $connectionArray += "ProvDBConnection"
    $connectionArray += "SfDBConnection"
    $connectionArray += "TrustDBConnection"
    $connectionArray += "LogDBConnection"
    $connectionArray += "ConfigDBConnection"
    $connectionArray += "AdminDBConnection"

    foreach ($command in $connectionArray) {

        try {
            $get = Invoke-Expression -Command "Get-$($command)"
        } catch {
            $get = $null
        }

        try {
            if (![string]::IsNullOrEmpty($get)) {
                Invoke-Expression -Command "Set-$($command) -DBConnection `$null -Force"
                $result.changed = $true
            }
        } catch {
            Fail-Json $result "An error occurred trying to reset the db connections. Error $($_)"
        }
    }

    if ($dropDb) {
        foreach ($database in $databases) {
            if ($database.Created) {
                try {
                    Start-DropDatabase -dbServer $databaseServer -dbPort $databaseServerPort -dbName $database.Name
                    $result.changed = $true

                    if ($debug) {
                        $result.removed = $($result.removed) + $database.Name -join ", "
                    }
                } catch {
                    Fail-Json $result "An error occurred while dropping the database $($database.Name). Error $($_)"
                }
            }
        }
    }
} else {

    $dbCreated = $false
    # Collect all the current databases of the SQL server
    $currentDatabases = Get-Database -dbServer $databaseServer -dbPort $databaseServerPort

    # Check if the required databases are allready there
    foreach ($db in $currentDatabases) {
        if ($databases.Name -match $db.Name) {
            $dbUpdate = $databases | Where-Object { $_.Name -eq $db.Name }
            $index = $databases.IndexOf($dbUpdate)
            $databases[$index].Created = $true
        }
    }

    # Create the database if the created switch is false
    foreach ($database in $databases) {
        if ($database.Created -eq $false) {
            try {
                New-XDDatabase -AdminAddress $env:ComputerName -SiteName $siteName -DataStore $database.Type -DatabaseServer $databaseServer -DatabaseName $database.Name -ErrorAction Stop | Out-Null
                $result.changed = $true
                $dbCreated = $true
            } catch {
                Fail-Json $result "An error occurred trying to create the $($database.Type) database. Error $($_)"
            }
        }
    }

    if ($dbCreated) {
        try {
            New-XDSite -DatabaseServer $databaseServer -LoggingDatabaseName $databaseNameLogging -MonitorDatabaseName $databaseNameMonitoring -SiteDatabaseName $databaseNameSite -SiteName $siteName -AdminAddress $env:ComputerName -ErrorAction Stop  | Out-Null
        } catch {
            Fail-Json $result "An error occurred creating the site. Error $($_)"
        }
    }

    # Compare the versions
    $version = Get-DatabaseVersion -dbServer $databaseServer -dbPort $databaseServerPort -dbName $databaseNameSite
    try {
        [string]$softwareVersion = (Get-WmiObject win32_product | Where-Object { $_.Name -like "*Citrix Broker Service*" }).Version
    } catch {
        Fail-Json $result "Failed collecting the installed version. Error: $($_)"
    }

    # If version match, and collect all machines from the site database
    if (!$dbCreated) {
        if ($softwareVersion.Contains($version)) {
            $machines = Get-DatabaseMachine -dbServer $databaseServer -dbPort $databaseServerPort -dbName $databaseNameSite
            $joined = $false
            if ($machines.MachineName -match $env:ComputerName) {
                $joined = $true
            }

            # If the server is not joined, it will join based on the exsisting controller form the database
            if ($joined -eq $false) {
                if ($machines.ItemArray.Count -eq 1) {
                    $controller = $machines.MachineName
                }

                try {
                    Add-XDController -SiteControllerAddress $controller  | Out-Null
                    $result.changed = $true
                } catch {
                    Fail-Json $result "An error occurred trying to join using controller $controller. Error: $($_)"
                }
            }
        }
    }

    $admins = Get-AdminAdministrator -AdminAddress $env:ComputerName
    $adminMatch = $admins | Where-Object {$_.Name -eq $adminGroup }
    if (!$adminMatch) {
        try {
            New-AdminAdministrator -AdminAddress $env:ComputerName -Name $adminGroup | Out-Null
            Add-AdminRight -AdminAddress $env:ComputerName -Administrator $adminGroup -Role $role -Scope $scope | Out-Null
            $result.changed = $true
        } catch {
            Fail-Json $result "An error occurred trying to create the Citrix administrator $AdminGroup. Error $($_)"
        }
    }

    $monConfig = Get-MonitorConfiguration -AdminAddress $env:ComputerName
    if ($monConfig.GroomApplicationInstanceRetentionDays -ne $groomingDays) {
        try {
            Set-MonitorConfiguration -AdminAddress $env:ComputerName -GroomApplicationInstanceRetentionDays $GroomingDays -GroomDeletedRetentionDays $GroomingDays -GroomFailuresRetentionDays $GroomingDays -GroomLoadIndexesRetentionDays $GroomingDays -GroomMachineHotfixLogRetentionDays $GroomingDays -GroomNotificationLogRetentionDays $GroomingDays -GroomResourceUsageDayDataRetentionDays $GroomingDays -GroomSessionsRetentionDays $GroomingDays -GroomSummariesRetentionDays $GroomingDays | Out-Null
            $result.changed = $true
        } catch {
            Fail-Json $result "An error occurred trying to change the grooming settings to $GroomingDays days. Error $($_)"
        }
    }

    $brokerSite = Get-BrokerSite -AdminAddress $env:ComputerName

    if (!$brokerSite.TrustRequestsSentToTheXmlServicePort) {
        Set-BrokerSite -AdminAddress $env:ComputerName -TrustRequestsSentToTheXmlServicePort $true | Out-Null
        $result.changed = $true
    }

    if ($brokerSite.ConnectionLeasingEnabled) {
        Set-BrokerSite -AdminAddress $env:ComputerName -ConnectionLeasingEnabled $false | Out-Null
        $result.changed = $true
    }

    if (!$brokerSite.LocalHostCacheEnabled) {
        Set-BrokerSite -AdminAddress $env:ComputerName -LocalHostCacheEnabled $true | Out-Null
        $result.changed = $true
    }

    $analyticSite = Get-AnalyticsSite -AdminAddress $env:ComputerName
    if ($analyticSite.Enabled) {
        Set-AnalyticsSite -AdminAddress $env:ComputerName -Enabled $false | Out-Null
        $result.changed = $true
    }
}

Exit-Json $result