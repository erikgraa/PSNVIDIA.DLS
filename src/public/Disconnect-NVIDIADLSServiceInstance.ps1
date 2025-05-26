<#
    .SYNOPSIS
    Disconnects from a NVIDIA DLS service instance.

    .DESCRIPTION
    Disconnects from a NVIDIA DLS service instance.

    .EXAMPLE
    Disconnect-NVIDIADLSServiceInstance -Server 'nls.fqdn'

    .NOTES
    Tested on NVIDIA DLS 3.5.0.

    .OUTPUTS
    None.

    .LINK
    https://ui.licensing.nvidia.com/api-doc/dls-api-docs.html
#>

function Disconnect-NVIDIADLSServiceInstance {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String]$Server
    )

    begin { }

    process {
        if (-not($PSBoundParameters.ContainsKey('Server'))) {
            try {
                $Server = (Get-Variable -Name '_NVIDIA_DLS_Default_Server' -Scope Global -ErrorAction SilentlyContinue).Value
            }
            catch { }
        }

        if ($Server) {
            if ($PSCmdlet.ShouldProcess($Server, 'Disconnect from NVIDIA DLS service instance')) {
                Clear-Variable -Name ('_NVIDIA_DLS_{0}' -f $Server) -Scope Global -Force -ErrorAction SilentlyContinue
                Clear-Variable -Name '_NVIDIA_DLS_Default_Server' -Scope Global -Force -ErrorAction SilentlyContinue
            }
        }
    }

    end { }
}