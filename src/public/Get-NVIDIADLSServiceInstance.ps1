<#
    .SYNOPSIS
    Retrieves NVIDIA DLS service instance details.

    .DESCRIPTION
    Retrieves NVIDIA DLS service instance details.

    .EXAMPLE
    Get-NVIDIADLSServiceInstance -Server 'nls.fqdn'

    .NOTES
    Tested on NVIDIA DLS 3.5.0.

    .OUTPUTS
    None.

    .LINK
    https://ui.licensing.nvidia.com/api-doc/dls-api-docs.html
#>

function Get-NVIDIADLSServiceInstance {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String]$Server     
    )

    begin {
        try {        
            $splat = @{}

            if ($PSBoundParameters.ContainsKey('Server')) {
                $splat.Add('Server', $Server)
            }

            $connection = Get-ServerConnection @splat

            if ($connection.SkipCertificateCheck -eq $true) {
                $splat.Add('SkipCertificateCheck', $true)
            }            

            $headers = @{
                'Authorization' = ('Bearer {0}' -f $connection.token)
            }
        }
        catch {
            throw $_
        }
    }

    process {
        try {
            $uri = ('https://{0}/service_instance_manager/v1/service-instance' -f $connection.Server)

            $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers @splat

            if ($null -eq $response) {
                throw $_
            }

            $response
        }
        catch {
            Write-Error -Message ("Error encountered retrieving service instance user: {0}" -f $Server, $_)
        }
    }

    end { }    
}