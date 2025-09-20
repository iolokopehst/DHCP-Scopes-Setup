<#
.SYNOPSIS
    Automates DHCP scope creation, option configuration, and server authorization on Windows Server.

.DESCRIPTION
    - Prompts for number of scopes, base subnet, scope names, and IP ranges
    - Creates all scopes
    - Sets default router (gateway) and DNS server (uses server IP)
    - Authorizes the DHCP server in AD
#>

# Ensure DHCP module and role are installed
if (-not (Get-WindowsFeature -Name DHCP)) {
    Install-WindowsFeature DHCP -IncludeManagementTools
    Write-Host "DHCP Server role installed."
}

Import-Module DhcpServer -ErrorAction Stop

# Get server IP to use as DNS
$ServerIP = (Get-NetIPAddress | Where-Object { $_.AddressFamily -eq 'IPv4' -and $_.IPAddress -notlike '169.254*' }).IPAddress
if (-not $ServerIP) { 
    Write-Host "Could not detect server IP. Please ensure server has a static IP." 
    exit 
}

# Prompt for input
$ScopeCount = Read-Host "Enter number of DHCP scopes to create"
[int]$ScopeCount = [int]$ScopeCount

$BaseSubnet = Read-Host "Enter base subnet (e.g., 192.168.1)"
$Gateway = Read-Host "Enter default gateway for scopes (or leave blank to skip)"

$Scopes = @()

for ($i=1; $i -le $ScopeCount; $i++) {
    Write-Host "`n--- Scope $i ---"
    $Name = Read-Host "Enter name for scope $i"
    $StartRange = Read-Host "Enter start IP suffix (e.g., 10 for $BaseSubnet.10)"
    $EndRange = Read-Host "Enter end IP suffix (e.g., 50 for $BaseSubnet.50)"
    $SubnetMask = Read-Host "Enter subnet mask (e.g., 255.255.255.0)"

    $Scopes += [PSCustomObject]@{
        Name = $Name
        StartIP = "$BaseSubnet.$StartRange"
        EndIP = "$BaseSubnet.$EndRange"
        SubnetMask = $SubnetMask
    }
}

# Create and configure scopes
foreach ($scope in $Scopes) {
    Write-Host "`nCreating scope $($scope.Name)..."
    Add-DhcpServerv4Scope -Name $scope.Name `
        -StartRange $scope.StartIP -EndRange $scope.EndIP `
        -SubnetMask $scope.SubnetMask `
        -State Active

    # Set options: Router (gateway) and DNS
    if ($Gateway -ne "") {
        Set-DhcpServerv4OptionValue -ScopeId $scope.StartIP -Router $Gateway
    }
    Set-DhcpServerv4OptionValue -ScopeId $scope.StartIP -DnsServer $ServerIP
}

# Authorize DHCP server in AD
Write-Host "`nAuthorizing DHCP server..."
Add-DhcpServerInDC -DnsName $env:COMPUTERNAME -IPAddress $ServerIP

Write-Host "`nAll DHCP scopes created, options set, and DHCP server authorized."
