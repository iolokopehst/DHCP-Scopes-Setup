<#
.SYNOPSIS
    Automated DHCP scopes setup with error handling.
.DESCRIPTION
    - Checks for Admin privileges
    - Installs DHCP role if missing
    - Prompts for scopes and ranges
    - Configures router and DNS options
    - Authorizes DHCP server in AD
    - Full error handling and pause
.NOTES
    Run as Administrator on your Domain Controller.
#>

try {
    # ----------------------------
    # Admin Check
    # ----------------------------
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Warning "This script must be run as Administrator. Exiting..."
        Start-Sleep -Seconds 5
        exit
    }

    # ----------------------------
    # Install DHCP Server Role if needed
    # ----------------------------
    try {
        if (-not (Get-WindowsFeature DHCP).Installed) {
            Write-Host "Installing DHCP Server role..."
            Install-WindowsFeature DHCP -IncludeManagementTools -ErrorAction Stop
            Write-Host "DHCP Server role installed successfully."
        } else {
            Write-Host "DHCP Server role already installed. Skipping installation."
        }
    }
    catch {
        Write-Error "Failed to install DHCP role: $_"
    }

    # ----------------------------
    # Prompt for number of scopes
    # ----------------------------
    $ScopeCount = Read-Host "Enter the number of DHCP scopes to create"
    if (-not [int]::TryParse($ScopeCount, [ref]$null)) {
        Write-Error "Invalid number entered. Exiting..."
        exit
    }

    # ----------------------------
    # Loop to collect scope info
    # ----------------------------
    $Scopes = @()
    for ($i = 1; $i -le $ScopeCount; $i++) {
        Write-Host "`nScope #$i:"
        $ScopeName = Read-Host "Enter scope name"
        $StartIP   = Read-Host "Enter starting IP address (e.g., 192.168.1.10)"
        $EndIP     = Read-Host "Enter ending IP address (e.g., 192.168.1.50)"
        $Subnet    = Read-Host "Enter subnet mask (e.g., 255.255.255.0)"
        $Scopes += [PSCustomObject]@{
            Name      = $ScopeName
            StartIP   = $StartIP
            EndIP     = $EndIP
            Subnet    = $Subnet
        }
    }

    # ----------------------------
    # Create scopes
    # ----------------------------
    foreach ($Scope in $Scopes) {
        try {
            Write-Host "`nCreating DHCP scope: $($Scope.Name)"
            Add-DhcpServerv4Scope -Name $Scope.Name -StartRange $Scope.StartIP -EndRange $Scope.EndIP -SubnetMask $Scope.Subnet -State Active -ErrorAction Stop

            # Set router and DNS options
            $NIC = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1
            $ServerIP = (Get-NetIPAddress -InterfaceIndex $NIC.ifIndex -AddressFamily IPv4 | Where-Object { $_.PrefixOrigin -eq "Manual" }).IPAddress
            if ($ServerIP) {
                Set-DhcpServerv4OptionValue -ScopeId $Scope.StartIP -Router $ServerIP -DnsServer $ServerIP -ErrorAction Stop
                Write-Host "Router and DNS options set to $ServerIP"
            } else {
                Write-Warning "Could not detect server IP for options. You may need to set router/DNS manually."
            }
        }
        catch {
            Write-Error "Failed to create or configure scope '$($Scope.Name)': $_"
        }
    }

    # ----------------------------
    # Authorize DHCP server
    # ----------------------------
    try {
        $ServerName = $env:COMPUTERNAME
        Write-Host "`nAuthorizing DHCP server in Active Directory..."
        Add-DhcpServerInDC -DnsName $ServerName -IPAddress $ServerIP -ErrorAction Stop
        Write-Host "DHCP server authorized successfully."
    }
    catch {
        Write-Error "Failed to authorize DHCP server: $_"
    }
}
catch {
    Write-Error "A fatal error occurred in the script: $_"
}
finally {
    Write-Host "`nDHCP setup script finished. Press any key to exit..."
    $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
