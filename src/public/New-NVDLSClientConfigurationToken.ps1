<#
    .SYNOPSIS
    Generates a new NVIDIA DLS client configuration token.

    .DESCRIPTION
    Generates a new NVIDIA DLS client configuration token.

    .PARAMETER Server
    Specifies the NVIDIA DLS service instance.

    .PARAMETER Path
    Specifies the path to save the client configuration token. Defaults to the working directory.

    .PARAMETER ScopeReferenceList
    Specifies the scope reference ID. Defaults to the service instance's scope reference id.

    .PARAMETER NodeId
    Specifies the node id. Defaults to the service instance's node id.

    .PARAMETER AddressType
    Specifies the address type. Defaults to IPV4. Valid options are IPV4 and FQDN.

    .PARAMETER LeasingPort
    Specifies the leasing port. Defaults to 443. Valid options are 443 and 8082.

    .PARAMETER Expiry
    Specifies the client configuration token expiry date.

    .PARAMETER PassThru
    Specifies that the client configuration token file will be passed thru as a System.IO.FileInfo object.

    .EXAMPLE
    New-NVDLSClientConfigurationToken -Server 'dls.fqdn' -PassThru

    .EXAMPLE
    New-NVDLSClientConfigurationToken -Server 'dls.fqdn' -Expiry (Get-Date).AddMonths(3)
    
    .EXAMPLE
    New-NVDLSClientConfigurationToken -Server 'dls.fqdn' -AddressType FQDN

    .NOTES
    Tested on NVIDIA DLS 3.5.0.

    .OUTPUTS
    None.
    [System.IO.FileInfo].    

    .LINK
    https://ui.licensing.nvidia.com/api-doc/dls-api-docs.html
#>

function New-NVDLSClientConfigurationToken {
    [CmdletBinding()]
    [OutputType([Void],[System.IO.FileInfo])]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String]$Server,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.IO.DirectoryInfo]$Path = (Get-Location).Path,

        [Parameter(Mandatory = $false)]
        [String[]]$ScopeReferenceList,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String]$NodeId,

        [Parameter(Mandatory = $false)]
        [ValidateSet('FQDN', 'IPV4')]
        [String]$AddressType = 'IPV4',

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('443', '8082')]
        [Int]$LeasingPort = 443,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [DateTime]$Expiry,

        [Parameter(Mandatory = $false)]
        [Switch]$PassThru
    )

    begin {
        try {
            $tokenDateTime = Get-Date -Date (Get-Date) -Format 'MM-dd-yyyy-hh-mm-ss'

            $filename = ('client_configuration_token_{0}' -f $tokenDateTime)

            $filePath = ('{0}\{1}.tok' -f $Path, $fileName)

            if (-not(Test-Path -Path $Path -PathType Container -ErrorAction SilentlyContinue)) {
                throw ('Cannot find directory {0}.' -f $Path)
            }

            $splat = @{}

            if ($PSBoundParameters.ContainsKey('Server')) {
                $splat.Add('Server', $Server)
            }

            $connection = Get-NVDLSConnection @splat        

            $headers = @{
                'Authorization' = ('Bearer {0}' -f $connection.token)
                'Content-Type' = 'application/json'
                'Accept' = 'application/json'
            }

            if (-not($PSBoundParameters.ContainsKey('ScopeReferenceList'))) {
                $licenseServer = Get-NVDLSLicenseServer @splat
                $ScopeReferenceList = @($licenseServer.scopeReference)
            }

            if (-not($PSBoundParameters.ContainsKey('NodeId'))) {
                $serviceInstance = Get-NVDLSInstance @splat
                $NodeId = $serviceInstance.high_availability_config.config.nodeList.node_id
            }

            $node = $serviceInstance.high_availability_config.config.nodelist | Where-Object { $_.network_location -eq $connection.Server -or $_.fqdn -eq $connection.Server }

            $role = $node.role 

            if ($AddressType -eq 'IPV4') {
                $address = $node.network_location
            }
            else {
                $address = $node.fqdn
            }            

            $addressTypeSelections = @{
                'node_id' = $NodeId
                'role' = $role
                'addressType' = $AddressType
                'address' = $address
            }

            $body = @{
                'scopeReferenceList' = $ScopeReferenceList
                'fulfillmentClassReferenceList' = @()
                'addressTypeSelections' = @($addressTypeSelections)
                'leasingPort' = $LeasingPort
            }

            if ($PSBoundParameters.ContainsKey('Expiry')) {
                $expiryShort = Get-Date -Date $Expiry -Format 'yyyy-MM-dd'

                $body.Add('expiry', $expiryShort)
            }            
            
            $body = $body | ConvertTo-Json -Compress
        }
        catch {
            throw $_
        }
    }

    process {
        try {
            $uri = ('https://{0}/service_instance_manager/v1/service-instance/compose-messenger-token' -f $connection.Server)

            $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body

            if ($null -eq $response) {
                throw $_
            }

            $response.messengerToken | Out-File -FilePath $filePath -NoNewline -Force -Encoding utf8

            if ($PSBoundParameters.ContainsKey('PassThru')) {
                Get-Item -Path $filePath
            }
        }
        catch {
            Write-Error -Message ("Error encountered generating client configuration token: {0}" -f $_)
        }
    }

    end { }
}