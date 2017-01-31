<#
	.NOTES
	===========================================================================
	 Created on:   	24/01/2017 16:13
	 Created by:   	Jim Moyle
	 GitHub link: 	https://github.com/JimMoyle/GUIDemo
	 Twitter: 		@JimMoyle
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>

function Get-XamlObject {
	[CmdletBinding()]
	param(
		[Parameter(Position = 0,
			 Mandatory = $true,
			 ValuefromPipelineByPropertyName = $true,
			 ValuefromPipeline = $true)]
		[Alias("FullName")]
		[System.String[]]$Path
	)

	BEGIN
	{
		Set-StrictMode -Version Latest
		$expandedParams = $null
		$PSBoundParameters.GetEnumerator() | ForEach-Object { $expandedParams += ' -' + $_.key + ' '; $expandedParams += $_.value }
		Write-Verbose "Starting: $($MyInvocation.MyCommand.Name)$expandedParams"
		$output = @{ }
		Add-Type -AssemblyName presentationframework, presentationcore
	} #BEGIN

	PROCESS {
		try
		{
			foreach ($xamlFile in $Path)
			{
				#Change content of Xaml file to be a set of powershell GUI objects
				$inputXML = Get-Content -Path $xamlFile -ErrorAction Stop
				[xml]$xaml = $inputXML -replace 'mc:Ignorable="d"', '' -replace "x:N", 'N' -replace 'x:Class=".*?"', '' -replace 'd:DesignHeight="\d*?"', '' -replace 'd:DesignWidth="\d*?"', ''
				$tempform = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $xaml -ErrorAction Stop))

				#Grab named objects from tree and put in a flat structure using Xpath
				$namedNodes = $xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]")
				$namedNodes | ForEach-Object {
					$output.Add($_.Name, $tempform.FindName($_.Name))
				} #foreach-object
			} #foreach xamlpath
		} #try
		catch
		{
			throw $error[0]
		} #catch
	} #PROCESS

	END
	{
		Write-Output $output
		Write-Verbose "Finished: $($MyInvocation.Mycommand)"
	} #END
}