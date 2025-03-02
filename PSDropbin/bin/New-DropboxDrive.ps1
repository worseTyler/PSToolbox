Function New-DropboxDrive {

	[CmdletBinding()] param(
		[Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
		[string]
		$Name,

		[Parameter()]
		[string]
		$Root = "\",

		[Parameter()]
		[string]
		$Description = $null,

		[Parameter()]
		[string]
		$Scope = "Global"
	)
	New-PSDrive -Name $Name -PSProvider Dropbox -Root $Root -Scope $Scope -Description $Description
}