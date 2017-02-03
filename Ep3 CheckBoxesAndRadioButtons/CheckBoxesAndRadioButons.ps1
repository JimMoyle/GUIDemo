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

	$path = '.\CheckBoxesAndRadioButtons'

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

#region RadioButton
	$wpf.RadioButton.add_Checked({
		
		#$this | Export-Clixml "$path\this.xml"
		#$_ | Export-Clixml "$path\DollarUnderscore.xml"
		
		$wpf.FinishTextBlockHypervisor.text = $this.content

	})

	$wpf.RadioButton1.add_Checked({
			
			$wpf.FinishTextBlockHypervisor.text = $this.content

		})

	$wpf.RadioButton2.add_Checked({
			
			$wpf.FinishTextBlockHypervisor.text = $this.content

		})

	$wpf.RadioButton3.add_Checked({
			
			$wpf.FinishTextBlockHypervisor.text = $this.content

		})

#endregion

#region Checkboxes
	$wpf.CheckBox.add_Checked({
			
			$wpf.FinishTextBlockCPU.text = $this.content

		})

	$wpf.CheckBox.add_UnChecked({
			
			$wpf.FinishTextBlockCPU.text = ''

		})

	$wpf.CheckBox1.add_Checked({
			
			$wpf.FinishTextBlockMemory.text = $this.content

		})

	$wpf.CheckBox1.add_UnChecked({
			
			$wpf.FinishTextBlockMemory.text = ''

		})

	$wpf.CheckBox2.add_Checked({
			
			$wpf.FinishTextBlockDisk.text = $this.content

		})

	$wpf.CheckBox2.add_UnChecked({
			
			$wpf.FinishTextBlockDisk.text = ''

		})


#endregion

#region defaults
	$wpf.FinishTextBlockHypervisor.text = $wpf.RadioButton.Content
#endregion

$wpf.Window.Showdialog() | Out-Null