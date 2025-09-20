# DHCP Scopes Setup

This PowerShell script automates **DHCP server setup and scope creation** on a Windows Server. It is designed for lab and demo environments to quickly provision multiple DHCP scopes, configure scope options, and authorize the DHCP server in Active Directory.

---

## What the Script Does

1. **Installs the DHCP Server role** if it is not already installed.  
2. **Prompts for user input**:
   - Number of DHCP scopes to create  
   - Base subnet (e.g., `192.168.1`)  
   - Default gateway for the scopes (optional)  
   - For each scope:  
     - Scope name  
     - Start IP suffix  
     - End IP suffix  
     - Subnet mask  
3. **Creates all scopes** on the DHCP server.  
4. **Sets scope options**:  
   - Default gateway (if provided)  
   - DNS server (automatically set to the server’s IP)  
5. **Authorizes the DHCP server** in Active Directory.  

After the script finishes, the DHCP server is fully configured and ready to serve clients.

---

## Requirements

- Windows Server 2019 or 2022  
- Administrator privileges to run PowerShell  
- DHCP Server role can be installed automatically by the script  
- Server must have a static IP address or already have a valid IP assigned  

---

## How to Use

1. **Download the script**: `DHCP-Scopes-Setup.ps1` from this repository.  
2. **Open PowerShell as Administrator** on your Windows Server.  
3. **Run the script**:

```powershell
.\DHCP-Scopes-Setup.ps1
