
<#

    .NOTES
    TODO: Check JWT token expiry.

#>

function Get-ServerConnection {
    param (
        [string]$Server
    )

    try {
        if (-not($Server)) {
            $Server = (Get-Variable -Name '_NVIDIA_DLS_Default_Server' -Scope Global -ErrorAction Stop).Value
        }

        $token = (Get-Variable -Name ('_NVIDIA_DLS_{0}' -f $Server) -Scope Global -ErrorAction Stop).Value

        $skipCertificateCheck = (Get-Variable -Name ('_NVIDIA_DLS_{0}_SkipCertificateCheck' -f $Server) -Scope Global -ErrorAction Stop).Value

        $hash = @{
            'Server' = $Server
            'Token' = $token | ConvertFrom-SecureString -AsPlainText
        }

        if ($skipCertificateCheck -eq $true) {
            $hash.Add('SkipCertificateCheck', $true)
        }

        $hash
    }
    catch {
        Write-Error 'Not connected to NVIDIA DLS service instance.' -RecommendedAction 'Please connect with the Connect-NVIDIADLSServer cmdlet.' -ErrorAction Stop
    }
}