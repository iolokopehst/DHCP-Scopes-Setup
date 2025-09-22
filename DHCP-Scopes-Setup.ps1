<#
.SYNOPSIS
Automated DHCP Scopes creation script with full error handling and logging.
.DESCRIPTION
- Self-elevates if not run as administrator
- Installs DHCP Server role if missing
- Prompts user for number of scopes and configuration for each
- Creates DHCP scopes, sets default gateway and DNS options
- Authorizes DHCP server in Active Directory
- Logs all actions and errors
#>

# ----------------------------
# Self-elevation
# ----------------------------
$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $IsAdmin) {
    Write-Warning "This script requires administrative privileges. Restarting with elevation..."
    Start-Process powershell.exe "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Host "`n=== DHCP Scopes Setup ===`n"

# ----------------------------
# Logging
# ----------------------------
$LogDir = "C:\Setup-DHCP"
$LogFile = "$LogDir\dhcp-scopes.log"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
Start-Transcript -Path $LogFile -Force

try {
    # ----------------------------
    # Install DHCP Server role if missing
    # ----------------------------
    $dhcpRole = Get-WindowsFeature DHCP
    if (-not $dhcpRole.Installed) {
        Write-Host "DHCP Server role not found. Installing..."
        Install-WindowsFeature -Name DHCP -IncludeManagementTools -ErrorAction Stop
        Write-Host "DHCP Server role installed successfully.`n"
        
        # Refresh PSModulePath
        $env:PSModulePath = [System.Environment]::GetEnvironmentVariable("PSModulePath","Machine")
    }

    # ----------------------------
    # Check if DhcpServer module exists
    # ----------------------------
    if (-not (Get-Module -ListAvailable -Name DhcpServer)) {
        Write-Error "The DhcpServer module cannot be found. You may need to restart the server to complete the DHCP Server installation."
        Read-Host "Press Enter to exit"
        exit 1
    }

    Import-Module DhcpServer -ErrorAction Stop

    # ----------------------------
    # Ask how many scopes to create
    # ----------------------------
    [int]$ScopeCount = Read-Host "How many DHCP scopes do you want to create?"

    $Scopes = @()
    for ($i = 1; $i -le $ScopeCount; $i++) {
        Write-Host "`nConfiguring scope $i of $ScopeCount"

        $ScopeName = Read-Host "Enter the name for scope $i"
        $Network = Read-Host "Enter the network for scope $ScopeName (e.g., 192.168.10.0)"
        $SubnetMask = Read-Host "Enter the subnet mask (e.g., 255.255.255.0)"
        $StartIP = Read-Host "Enter the starting IP (default: .10)"
        $EndIP = Read-Host "Enter the ending IP (default: .254)"
        $Gateway = Read-Host "Enter the default gateway (default: first IP of network)"
        $DNSServer = Read-Host "Enter the DNS server (default: this server's IP)"

        # Fill defaults if left blank
        if ([string]::IsNullOrWhiteSpace($StartIP)) { $StartIP = "$($Network.Substring(0,$Network.LastIndexOf('.')+1))10" }
        if ([string]::IsNullOrWhiteSpace($EndIP)) { $EndIP = "$($Network.Substring(0,$Network.LastIndexOf('.')+1))254" }
        if ([string]::IsNullOrWhiteSpace($Gateway)) { $Gateway = "$($Network.Substring(0,$Network.LastIndexOf('.')+1))1" }
        if ([string]::IsNullOrWhiteSpace($DNSServer)) { 
            $DNSServer = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notlike "*Loopback*"} | Select-Object -First 1 -ExpandProperty IPAddress) 
        }

        $Scopes += [PSCustomObject]@{
            Name = $ScopeName
            Network = $Network
            SubnetMask = $SubnetMask
            StartIP = $StartIP
            EndIP = $EndIP
            Gateway = $Gateway
            DNSServer = $DNSServer
        }
    }

    # ----------------------------
    # Create scopes and set options
    # ----------------------------
    foreach ($scope in $Scopes) {
        Write-Host "`nCreating scope $($scope.Name)..."
        try {
            Add-DhcpServerv4Scope -Name $scope.Name -StartRange $scope.StartIP -EndRange $scope.EndIP -SubnetMask $scope.SubnetMask -State Active -ErrorAction Stop

            # Set router and DNS
            Set-DhcpServerv4OptionValue -ScopeId $scope.Network -Router $scope.Gateway -DnsServer $scope.DNSServer -ErrorAction Stop

            Write-Host "Scope $($scope.Name) created and configured successfully."
        } catch {
            Write-Error "Failed to create or configure scope $($scope.Name): $_"
        }
    }

    # ----------------------------
    # Authorize DHCP server in AD
    # ----------------------------
    try {
        $ServerIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notlike "*Loopback*"} | Select-Object -First 1 -ExpandProperty IPAddress)
        Add-DhcpServerInDC -DnsName $env:COMPUTERNAME -IpAddress $ServerIP -ErrorAction Stop
        Write-Host "`nDHCP server authorized successfully."
    } catch {
        Write-Error "Failed to authorize DHCP server: $_"
    }

} catch {
    Write-Error "A fatal error occurred: $_"
} finally {
    Stop-Transcript
    Write-Host "`nDHCP scopes setup completed."
    Read-Host "Press Enter to exit"
}
