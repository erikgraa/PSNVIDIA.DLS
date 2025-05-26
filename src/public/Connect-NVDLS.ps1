 <#
    .SYNOPSIS
    Connects to a NVIDIA DLS service instance.

    .DESCRIPTION
    Connects to a NVIDIA DLS service instance.

    .PARAMETER Server
    Specifies the NVIDIA DLS service instance.
    
    .PARAMETER Credential
    Specifies the NVIDIA DLS service instance administrator credential.

    .PARAMETER SkipCertificateCheck
    Specifies that certificates will not be checked.

    .EXAMPLE
    Connect-NVDLS -Server 'dls.fqdn' -Credential $credential

    .NOTES
    Tested on NVIDIA DLS 3.5.0.

    .OUTPUTS
    None.

    .LINK
    https://ui.licensing.nvidia.com/api-doc/dls-api-docs.html
#>

function Connect-NVDLS {
    [CmdletBinding()]
    [OutputType([Void])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$Server,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]$Credential,
        
        [Parameter(Mandatory = $false)]
        [Switch]$SkipCertificateCheck
    )

    begin {
        try {
            if ($PSEdition -eq 'Core') {
                $PSDefaultParameterValues.Add('Invoke-RestMethod:SkipCertificateCheck', $SkipCertificateCheck)
            }

            $headers = @{ 'Content-Type' = 'application/json' }
  
            $body = @{
                'username' = $credential.GetNetworkCredential().UserName
                'password' = $credential.GetNetworkCredential().Password
            } | ConvertTo-Json -Compress            
        }
        catch {
            throw $_
        }
    }

    process {
        try {
            $response = Invoke-RestMethod -Method Post -Uri ('https://{0}/auth/v1/login' -f $Server) -Headers $headers -Body $body
    
            if ($null -eq $response) {
                throw $_
            }

            Set-Variable -Name ('_NVIDIA_DLS_{0}' -f $Server) -Scope Global -Value (ConvertTo-SecureString -AsPlaintext -Force -String $response.token)

            if ($null -eq ${global:_NVIDIA_DLS_Default_Server}) {
                Set-Variable -Name '_NVIDIA_DLS_Default_Server' -Scope Global -Value $Server
            }
        }
        catch {
            Write-Error -Message ("Error encountered logging into NVIDIA DLS {0}: {1}" -f $Server, $_) -RecommendedAction 'Verify username and password and that the server is operational'
        }
    }

    end { }
}