<#
    .SYNOPSIS
    Retrieves NVIDIA DLS service instance lease(s).

    .DESCRIPTION
    Retrieves NVIDIA DLS service instance lease(s).

    .EXAMPLE
    Get-NVIDIADLSServiceInstanceLease -Server 'nls.fqdn'

    .NOTES
    Tested on NVIDIA DLS 3.5.0.
    TODO: 
        * Pagination.
        
    .OUTPUTS
    None.

    .LINK
    https://ui.licensing.nvidia.com/api-doc/dls-api-docs.html
#>

function Get-NVIDIADLSServiceInstanceLease {
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

            $serviceInstanceUser = Get-NVIDIADLSServiceInstanceUser

            $virtualGroupId = $serviceInstanceUser.userScope.virtualGroupId
            $licenseServerId = $serviceInstanceUser.userScope.licenseServerId
            $orgName = $serviceInstanceUser.orgName
        }
        catch {
            throw $_
        }
    }

    process {
        try {
            $uri = ('https://{0}/admin/v1/org/{1}/virtual-groups/{2}/leases/all?license_server_ids={3}' -f $connection.Server, $orgName, $virtualGroupId, $licenseServerId)

            $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers @splat

            if ($null -eq $response) {
                throw $_
            }

            $response
        }
        catch {
            Write-Error -Message ("Error encountered retrieving license server details: {0}" -f $Server, $_)
        }
    }

    end { }    
}