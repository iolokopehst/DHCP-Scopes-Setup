# DHCP Scope Automation Script

This PowerShell script automates the creation of multiple DHCP scopes on a Windows Server.

## What it does
- Prompts the user for:
  - Number of scopes
  - Base subnet
  - Scope names
  - IP ranges
- Automatically creates all the scopes in the DHCP server role.
- Optionally sets a default gateway for each scope.

## Usage
1. Make sure the **DHCP Server role** is installed on your Windows Server.
2. Download `DHCP-Scopes-Setup.ps1` from this repository.
3. Run PowerShell as Administrator.
4. Run the script:
   ```powershell
   .\DHCP-Scopes-Setup.ps1
