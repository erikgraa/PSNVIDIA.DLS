<#
    .SYNOPSIS
    Generates a new NVIDIA DLS client configuration token.

    .DESCRIPTION
    Generates a new NVIDIA DLS client configuration token.

    .EXAMPLE
    New-NVIDIADLSClientConfigurationToken -Server 'nls.fqdn' -PassThru

    .EXAMPLE
    New-NVIDIADLSClientConfigurationToken -Server 'nls.fqdn' -Expiry (Get-Date).AddMonths(3)
    
    .EXAMPLE
    New-NVIDIADLSClientConfigurationToken -Server 'nls.fqdn' -AddressType FQDN

    .NOTES
    Tested on NVIDIA DLS 3.5.0.

    .OUTPUTS
    None.
    [System.IO.FileInfo].    

    .LINK
    https://ui.licensing.nvidia.com/api-doc/dls-api-docs.html
#>

function New-NVIDIADLSClientConfigurationToken {
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
        [DateTime]$Expiry = [DateTime]::Now.AddDays(30),    

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

            $connection = Get-ServerConnection @splat

            if ($connection.SkipCertificateCheck -eq $true) {
                $splat.Add('SkipCertificateCheck', $true)
            }            

            $headers = @{
                'Authorization' = ('Bearer {0}' -f $connection.token)
                'Content-Type' = 'application/json'
                'Accept' = 'application/json'
            }

            if (-not($PSBoundParameters.ContainsKey('ScopeReferenceList'))) {
                $licenseServer = Get-NVIDIADLSLicenseServer
                $ScopeReferenceList = @($licenseServer.licenseServer.scopeReference)
            }

            if (-not($PSBoundParameters.ContainsKey('NodeId'))) {
                $serviceInstance = Get-NVIDIADLSServiceInstance @splat
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

            $expiryShort = Get-Date -Date $Expiry -Format 'yyyy-MM-dd'

            $body = @{
                'scopeReferenceList' = $ScopeReferenceList
                'fulfillmentClassReferenceList' = @()
                'addressTypeSelections' = @($addressTypeSelections)
                'expiry' = $expiryShort
                'leasingPort' = $LeasingPort
            } | ConvertTo-Json -Compress
        }
        catch {
            throw $_
        }
    }

    process {
        try {
            $uri = ('https://{0}/service_instance_manager/v1/service-instance/compose-messenger-token' -f $connection.Server)

            $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body @splat

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