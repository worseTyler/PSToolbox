

Import-Module -Name $PSScriptRoot\..\Modules\IntelliTect.Common

Function Script:Initialize-TestGitRepo {
    [CmdletBinding()]
    param ()
    $tempDirectory = Get-TempDirectory
    try {
        Push-Location $tempDirectory
    }
    finally {
        Pop-Location
    }

}


Describe "Regsiter-AutoDispose" {
    It "Verify that dispose is called" {
        $sampleDisposeObject = Get-SampleDisposeObject
        Register-AutoDispose ($sampleDisposeObject) {}
       $sampleDisposeObject.IsDisposed | Should Be $true
    }
}

