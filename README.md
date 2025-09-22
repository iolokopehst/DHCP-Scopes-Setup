# DHCP Scopes Setup Script

## Overview
This PowerShell script automates the creation and configuration of DHCP scopes on a Windows Server. It includes:  

- **Automatic elevation** if not run as administrator  
- **DHCP Server role installation** if missing  
- **Mandatory input** — cannot skip required fields  
- **Full IP enforcement** — users must enter full IP addresses  
- **Scope creation** with DNS and default gateway configuration  
- **DHCP server authorization** in Active Directory  
- **Logging** to `C:\Setup-DHCP\dhcp-scopes.log`  
- **Error handling** for all major operations  

This script is designed to make DHCP setup faster, safer, and more consistent for lab environments, testing, or demonstrations.

---

## Requirements
- Windows Server 2016 or later  
- PowerShell 5.1+  
- Administrative privileges  

> **Note:** The script must be run as administrator. If not, it will automatically restart itself with elevation.

---

## Usage

1. Download the `DHCP-Scopes-Setup.ps1` file from this repository.  
2. Right-click the file and select **Run with PowerShell**, or run it in an elevated PowerShell session.  
3. The script will prompt you for the number of DHCP scopes to create.  
4. For each scope, enter the following **mandatory fields**:  
   - Scope Name  
   - Network (e.g., `192.168.10.0`)  
   - Subnet Mask (e.g., `255.255.255.0`)  
   - Starting IP (full IP required, e.g., `192.168.10.10`)  
   - Ending IP (full IP required, e.g., `192.168.10.254`)  
   - Default Gateway (full IP required, e.g., `192.168.10.1`)  
   - DNS Server (full IP required, typically the server’s IP)  
5. The script will automatically:  
   - Install the DHCP Server role if missing  
   - Create all scopes  
   - Configure router and DNS options  
   - Authorize the DHCP server in Active Directory  
6. At the end, the script will pause so you can review any messages or errors. All actions are logged to `C:\Setup-DHCP\dhcp-scopes.log`.

---

## Verification

- To verify scopes were created:  
```powershell
Get-DhcpServerv4Scope
