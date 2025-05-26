
<#

    .NOTES
    TODO: Check JWT token expiry.

#>

function Get-NVDLSConnection {
    param (
        [string]$Server
    )

    try {
        if (-not($Server)) {
            $Server = (Get-Variable -Name '_NVIDIA_DLS_Default_Server' -Scope Global -ErrorAction Stop).Value
        }

        $token = (Get-Variable -Name ('_NVIDIA_DLS_{0}' -f $Server) -Scope Global -ErrorAction Stop).Value

        $hash = @{
            'Server' = $Server
            'Token' = $token | ConvertFrom-SecureString -AsPlainText
        }

        $hash
    }
    catch {
        Write-Error 'Not connected to NVIDIA DLS service instance.' -RecommendedAction 'Please connect with the Connect-NVDLS cmdlet.' -ErrorAction Stop
    }
}