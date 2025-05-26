<#
    .SYNOPSIS
    Retrieves NVIDIA DLS service instance details.

    .DESCRIPTION
    Retrieves NVIDIA DLS service instance details.

    .PARAMETER Server
    Specifies the NVIDIA DLS service instance.    

    .EXAMPLE
    Get-NVDLSInstance    

    .EXAMPLE
    Get-NVDLSInstance -Server 'dls.fqdn'

    .NOTES
    Tested on NVIDIA DLS 3.5.0.

    .OUTPUTS
    [PSCustomObject].

    .LINK
    https://ui.licensing.nvidia.com/api-doc/dls-api-docs.html
#>

function Get-NVDLSInstance {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
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

            $connection = Get-NVDLSConnection @splat        

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

            $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers

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