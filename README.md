# PSNVIDIA.DLS

[![MIT licensed](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/erikgraa/PSNVIDIA.DLS/refs/heads/main/LICENSE)
![PowerShell Gallery Downloads](https://img.shields.io/powershellgallery/dt/PSNVIDIA.DLS?label=PowerShell%20Gallery&color=green)
![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/PSNVIDIA.DLS?color=green)

> This PowerShell module lets one accomplish various tasks with the NVIDIA Delegated License Service (DLS)

> [!TIP]
> Read the related blog post at https://blog.graa.dev/PowerShell-NVIDIADLS

## 🚀 Features 

* Generate client configuration token
* Retrieve DLS service instance information
* Retrieve DLS service instance leases

## 📄 Prerequisites

### PowerShell version

> [!IMPORTANT]  
> At present only PowerShell 7 is supported, and testing has been done on PowerShell `7.5.1`

### NVIDIA DLS

> [!NOTE]  
> This module has been tested on NVIDIA DLS `3.4.1` and `3.5.0`

## 📦 Installation

Install the version that is published to the PowerShell Gallery:

```powershell
Install-Module -Name PSNVIDIA.DLS
```

## 🔧 Usage

### Connect to NVIDIA DLS

```powershell
# Login with the DLS administrator account - the default username is dls_admin
$credential = Get-Credential

Connect-NVDLS -Server 'dls.fqdn' -Credential $credential
```

### Retrieve service instance information

```powershell
Get-NVDLSInstance
```

### Generate client configuration token

> [!NOTE]
> Unless the Path parameter is passed, the file with the token will end up in the current working directory.

```powershell
New-NVDLSClientConfigurationToken -Path C:\Tokens -PassThru
```

Optionally with a specific expiration date, e.g. 3 months:

```powershell
New-NVDLSClientConfigurationToken -Expiry (Get-Date).AddMonths(3)
```

### Disconnect from NVIDIA DLS

```powershell
Disconnect-NVDLS
```

## ✨ Credits

> [!NOTE]
> This PowerShell module is unofficial and not supported by NVIDIA in any way