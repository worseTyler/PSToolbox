Function Copy-Item {

[CmdletBinding(DefaultParameterSetName='Path', SupportsShouldProcess=$true, ConfirmImpact='Medium', SupportsTransactions=$true, HelpUri='http://go.microsoft.com/fwlink/?LinkID=113292')]
param(
    [Parameter(ParameterSetName='Path', Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [string[]]
    ${Path},

    [Parameter(ParameterSetName='LiteralPath', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
    [Alias('PSPath')]
    [string[]]
    ${LiteralPath},

    [Parameter(Position=1, ValueFromPipelineByPropertyName=$true)]
    [string]
    ${Destination},

    [switch]
    ${Container},

    [switch]
    ${Force},

    [string]
    ${Filter},

    [string[]]
    ${Include},

    [string[]]
    ${Exclude},

    [switch]
    ${Recurse},

    [switch]
    ${PassThru},

    [Parameter(ValueFromPipelineByPropertyName=$true)]
    [pscredential]
    [System.Management.Automation.CredentialAttribute()]
    ${Credential})

begin
{
    Function Get-PathProvider
    {
        (get-psdrive -name ((Force-Resolve-Path($args[0])) | split-path -Qualifier).Replace(":","")).Provider.Name
    }

    Function Force-Resolve-Path {
        <#
        .SYNOPSIS
            Calls Resolve-Path but works for files that don't exist.
        .REMARKS
            From http://devhawk.net/2010/01/21/fixing-powershells-busted-resolve-path-cmdlet/
        #>
        param (
            [string] $FileName
        )

        $FileName = Resolve-Path $FileName -ErrorAction SilentlyContinue `
                                           -ErrorVariable _frperror
        if (-not($FileName)) {
            $FileName = $_frperror[0].TargetObject
        }

        return $FileName
    }

    try {
        $outBuffer = $null
        if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
        {
            $PSBoundParameters['OutBuffer'] = 1
        }

        $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Management\Copy-Item', [System.Management.Automation.CommandTypes]::Cmdlet)
        $scriptCmd = {& $wrappedCmd @PSBoundParameters }

        # we require these two parameters
        if ($PSBoundParameters['Path'] -and $PSBoundParameters['Destination'])
        {
            $incoming = $PSBoundParameters['Path']
            $outgoing = $PSBoundParameters['Destination']

            $incomingLocal = $TRUE
            $incomingDropbox = $TRUE
            $outgoingLocal = $TRUE
            $outgoingDropbox = $TRUE

            # determine the provider of each parameter
            $incoming | % {
                $tempProvider = Get-PathProvider $_
                if ($tempProvider -ne "FileSystem") { $incomingLocal = $FALSE }
                if ($tempProvider -ne "Dropbox") { $incomingDropbox = $FALSE }
            }

            $outgoing | % {
                $tempProvider = Get-PathProvider $_
                if ($tempProvider -ne "FileSystem") { $outgoingLocal = $FALSE }
                if ($tempProvider -ne "Dropbox") { $outgoingDropbox = $FALSE }
            }

            # invoke a custom command, if appropriate
            if ($incomingLocal -and $outgoingDropbox)
            {
                $scriptCmd = {& Copy-LocalToDropbox (Force-Resolve-Path($incoming)) (Force-Resolve-Path($outgoing)) }
            }

            if ($incomingDropbox -and $outgoingLocal)
            {
                $scriptCmd = {& Copy-DropboxToLocal (Force-Resolve-Path($incoming)) (Force-Resolve-Path($outgoing)) }
            }
        }
        
        $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
        $steppablePipeline.Begin($PSCmdlet)
    } catch {
        throw
    }
}

process
{
    try {
        $steppablePipeline.Process($_)
    } catch {
        throw
    }
}

end
{
    try {
        $steppablePipeline.End()
    } catch {
        throw
    }
}
<#

.ForwardHelpTargetName Copy-Item
.ForwardHelpCategory Cmdlet

#>

}