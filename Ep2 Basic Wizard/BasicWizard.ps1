<#
	.NOTES
	===========================================================================
	 Created on:   	27/01/2017
	 Created by:   	Jim Moyle
	 GitHub link: 	https://github.com/JimMoyle/GUIDemo
	 Twitter: 		@JimMoyle
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>

function Get-XamlObject
{
	[CmdletBinding()]
	param (
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

		$wpfObjects = @{ }
		Add-Type -AssemblyName presentationframework, presentationcore

	} #BEGIN

	PROCESS
	{
		try
		{
			foreach ($xamlFile in $Path)
			{
				#Change content of Xaml file to be a set of powershell GUI objects
				$inputXML = Get-Content -Path $xamlFile -ErrorAction Stop
				$inputXMLClean = $inputXML -replace 'mc:Ignorable="d"', '' -replace "x:N", 'N' -replace 'x:Class=".*?"', '' -replace 'd:DesignHeight="\d*?"', '' -replace 'd:DesignWidth="\d*?"', ''
				[xml]$xaml = $inputXMLClean
				$reader = New-Object System.Xml.XmlNodeReader $xaml -ErrorAction Stop
				$tempform = [Windows.Markup.XamlReader]::Load($reader)

				#Grab named objects from tree and put in a flat structure
				$namedNodes = $xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]")
				$namedNodes | ForEach-Object {

					$wpfObjects.Add($_.Name, $tempform.FindName($_.Name))

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
		Write-Output $wpfObjects
	} #END
}

$path = 'E:\JimM\Dropbox\Dropbox (Personal)\ScriptScratch\YouTube\Basic Wizard\Basic Wizard'

$wpf = Get-ChildItem -Path $path -Filter *.xaml -file | Where-Object { $_.Name -ne 'App.xaml' } | Get-XamlObject

$wpf.WizardWindowFrame.NavigationService.Navigate($wpf.TitlePage) | Out-Null

$wpf.titleButtonNext.add_Click({
		$wpf.WizardWindowFrame.NavigationService.Navigate($wpf.MiddlePage)
	})

$wpf.middleButtonNext.add_Click({
		$wpf.WizardWindowFrame.NavigationService.Navigate($wpf.FinishPage)
	})

$wpf.middleButtonBack.add_Click({
		$wpf.WizardWindowFrame.NavigationService.Navigate($wpf.TitlePage)
	})

$wpf.FinishButtonBack.add_Click({
		$wpf.WizardWindowFrame.NavigationService.Navigate($wpf.MiddlePage)
	})

$wpf.WizardWindow.Showdialog() | Out-Null