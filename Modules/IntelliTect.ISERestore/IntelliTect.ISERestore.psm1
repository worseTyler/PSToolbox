


function script:Get-HistoryCsvHeader() {
    $historyHeader = @()
    $historyHeader += '#TYPE Microsoft.PowerShell.Commands.HistoryInfo'
    $historyHeader += '"Id","CommandLine","ExecutionStatus","StartExecutionTime","EndExecutionTime"'
    return $historyHeader.Clone();
}

function script:Restore-History([string] $historyLogFile, [switch]$passthru) {
    # See http://jamesone111.wordpress.com/2012/01/28/adding-persistent-history-to-powershell/ to save history across sessions
    # For more history stuff check out http://orsontyrell.blogspot.ca/2013/11/true-powershell-command-history.html
    Write-Host "Restoring last session history from $historyLogFile..."
    $MaximumHistoryCount = 2048;
    $global:historyLogFile = $historyLogFile
    $truncateLogLines = 1000
    $history = Get-HistoryCsvHeader
    $history > $historyLogFile
    if (Test-Path $historyLogFile) {
        $historyLogFileContents=(get-content $historyLogFile)
        #TODO: Change so that Select -Unique excludes the ID number and DateTime stamps which currently makes all items unique.
        $csvImport = Import-Csv $historyLogFile
        if($csvImport -and $csvImport.Count -gt 0) {
            $history += $csvImport
            $history = $history[-([math]::Min($history.Length, $truncateLogLines))..-1]
            # $history += $historyLogFileContents[-([math]::Min($historyLogFileContents.Length, $truncateLogLines))..-1] | where {$_ -match '^"\d+"'} | select -Unique
            Debug
            $History | Add-History -Passthru:$passthru # -errorAction SilentlyContinue
            $history | Export-Csv -Path $historyLogFile -Append -Confirm:$false
        }
    }
}

Function Export-ISEPowerShellTabPwd {
    [CmdletBinding()]
    param([Microsoft.PowerShell.Host.ISE.PowerShellTab] $Tab, [string]$Path)

    $Path > ([io.path]::ChangeExtension( $profile , "$($Tab.DisplayName).WorkingDirectory.txt"))
}

Function Import-ISEPowerShellTabPwd {
    [CmdletBinding()]
    param([Microsoft.PowerShell.Host.ISE.PowerShellTab] $Tab)

    $pwdFile = ([io.path]::ChangeExtension( $profile , "$($Tab.DisplayName).WorkingDirectory.txt"))
    if (Test-Path $pwdFile){
        $path = Get-Content $pwdFile
        return $path
    }
    return $null
}








try {
    $currentTabTitle = $null; 
    if(Test-path variable:psise) {
    #    if($psise.CurrentFile -and (Test-Path $psise.CurrentFile.FullPath)) {
    #        Set-Location (Split-Path $psise.CurrentFile.FullPath)
    #    }
        $currentTabTitle = ".$($psise.CurrentPowerShellTab.DisplayName)"
    }
    # Write-Host "`$currentTabTitle = $currentTabTitle"
    Restore-History ([io.path]::ChangeExtension( $profile , "$currentTabTitle.CommandHistory.csv"))
}
catch {
    Write-Error $_
    Write-Host "Error: (just after restore-history): $_"
}



if(Test-Path variable:psise) {
    $path = Import-ISEPowerShellTabPwd $psise.CurrentPowerShellTab
    if ($path){
        Set-Location $path
    }
}


Function Prompt { 
    if(Test-Path variable:psise) {
        Export-ISEPowerShellTabPwd $psise.CurrentPowerShellTab $pwd.Path
    }
    "$(Get-Location)> "
 }
