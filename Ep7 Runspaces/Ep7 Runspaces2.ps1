<#
	.NOTES
	===========================================================================
	 Created on:   	2017/03/27
	 Created by:   	Jim Moyle
	 GitHub link: 	https://github.com/JimMoyle/GUIDemo
	 Twitter: 		@JimMoyle
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>
#region Episode 2 code
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

	$path = Join-Path $PSScriptRoot '\Ep7 Runspaces'

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
#endregion


$wpf.titleButton.add_Click({

    $runspace = [runspacefactory]::CreateRunspace()
    #$runspace | Get-Member
    $powerShell = [powershell]::Create()
    #$powerShell | Get-Member
    $powerShell.runspace = $runspace
    $runspace.Open()

    [void]$PowerShell.AddScript({

        Wait-Debugger
        Start-Sleep -Seconds $wpf.titleTextBox.text
        $wpf.titleTextBlock.Text = "$($wpf.titleTextBox.text) second sleep finished"

    })

    $asyncObject = $PowerShell.BeginInvoke()
})


$wpf.Window.ShowDialog() | Out-Null