<#
	.NOTES
	===========================================================================
	 Created on:   	2017/04/07
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
				#Wait-Debugger
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

#Set Starting path and create Synchronised hash table to be read across multiple runspaces
$script:syncHash = [hashtable]::Synchronized(@{ })
$syncHash.path = Join-Path $PSScriptRoot '\Ep8 Runspaces Pt2'

#Load function into Sessionstate object for injection into runspace
$ssGetXamlObject = Get-Content Function:\Get-XamlObject -ErrorAction Stop
$ssfeGetXamlObject = New-Object System.Management.Automation.Runspaces.SessionStateFunctionEntry -ArgumentList 'Get-XamlObject', $ssGetXamlObject

#Add Function to session state
$InitialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
$InitialSessionState.Commands.Add($ssfeGetXamlObject)
			
$runspace = [runspacefactory]::CreateRunspace($InitialSessionState) #Add Session State to runspace at creation
$powerShell = [powershell]::Create()
$powerShell.runspace = $runspace
$runspace.ThreadOptions = "ReuseThread" #Helps to prevent memory leaks, show runspace config in console
$runspace.ApartmentState = "STA" #Needs to be in STA mode for WPF to work
$runspace.Open()
$runspace.SessionStateProxy.SetVariable("syncHash",$syncHash)

[void]$PowerShell.AddScript({

	$wpf = Get-ChildItem -Path $syncHash.path -Filter *.xaml -file | Where-Object { $_.Name -ne 'App.xaml' } | Get-XamlObject
	$wpf.GetEnumerator() | ForEach-Object {$script:SyncHash.add($_.name,$_.value)} #Add all WPF objects to synchash variable

	#Section Timer
		#We'll create a timer, this is for UI responsivness as Dispatcher.invoke is slow as a depressed slug!
		
		$updateBlock = {
			if ($syncHash.watchnumber -or $syncHash.titleResultTextBlock.Text -ne $syncHash.watchedNumber){
				$syncHash.titleResultTextBlock.Text = $syncHash.watchedNumber
			}
			$syncHash.titleTimerTextBlock.Text = $syncHash.finalTime

			#Section for runspace cleanup
				$syncHash.rs = Get-Runspace
				$syncHash.middleBusyTextBlock.text = $syncHash.rs | Where-Object {$_.RunspaceAvailability -eq 'Busy'} | Measure-Object | Select-Object -ExpandProperty Count
				$syncHash.middleAvailableTextBlock.text = $syncHash.rs | Where-Object {$_.RunspaceAvailability -eq 'Available'} | Measure-Object | Select-Object -ExpandProperty Count
				$syncHash.middleOpenTextBlock.text = $syncHash.rs | Where-Object {$_.RunspaceAvailability -eq 'Open'} | Measure-Object | Select-Object -ExpandProperty Count
				$syncHash.middleTotalTextBlock.text = $syncHash.rs | Measure-Object | Select-Object -ExpandProperty Count
			#Endsection
		}

		$timer = New-Object System.Windows.Threading.DispatcherTimer
		# Which will fire 100 times every second        
		$timer.Interval = [TimeSpan]"0:0:0.01"
		# And will invoke the $updateBlock method         
		$timer.Add_Tick($updateBlock)
		# Now start the timer running        
		$timer.Start()
		if ($timer.IsEnabled)
		{
			Write-Output 'UI timer started'
		}

	#EndSection

	#Section Navigation buttons
		$syncHash.WizardWindowFrame.NavigationService.Navigate($syncHash.TitlePage) | Out-Null
		$syncHash.titleButtonNext.add_Click({

			$syncHash.WizardWindowFrame.NavigationService.Navigate($syncHash.MiddlePage)
		})
		$syncHash.middleButtonNext.add_Click({
			$syncHash.WizardWindowFrame.NavigationService.Navigate($syncHash.FinishPage)
		})
		$syncHash.middleButtonBack.add_Click({
			$syncHash.WizardWindowFrame.NavigationService.Navigate($syncHash.TitlePage)
		})
		$syncHash.FinishButtonBack.add_Click({
			$syncHash.WizardWindowFrame.NavigationService.Navigate($syncHash.MiddlePage)
		})
	#EndSection

	#Section Dispatcher vs Timer

		$syncHash.titleDispatcherButton.add_Click({

			$syncHash.iterations = $syncHash.titleTextBox.text
			$syncHash.titleDispatcherTextBlock.Text = ''
			$syncHash.titleResultTextBlock.Text = ''

			$runspace = [runspacefactory]::CreateRunspace()
			$powerShell = [powershell]::Create()
			$powerShell.runspace = $runspace
			$runspace.ThreadOptions = 'ReuseThread'
			$runspace.ApartmentState = 'STA'
			$runspace.Open()
			$runspace.SessionStateProxy.SetVariable("syncHash",$syncHash)

			[void]$PowerShell.AddScript({
				$result = Measure-Command { # Using measure command to see how long entire process takes
					1..$syncHash.iterations | ForEach-Object {
						$syncHash.titleResultTextBlock.Dispatcher.Invoke([action]{
							$syncHash.titleResultTextBlock.Text = "$_" #For each number we update the UI via dispatcher
						})
					}
				}
				$syncHash.watchednumber = $syncHash.iterations #ignore as it stops race conditions between timer and dispatcher method
				$syncHash.titleDispatcherTextBlock.Dispatcher.Invoke([action]{
					$syncHash.titleDispatcherTextBlock.Text = "$("{0:N0}" -f $result.TotalMilliseconds) ms" #update UI with total time taken
				})
			})

			#start runspace and save details about runspace for later use
			$syncHash.Powershell = $PowerShell 
			$syncHash.AsyncObject = $PowerShell.BeginInvoke()

		})

		$syncHash.titleTimerButton.add_Click({

			$syncHash.iterations = $syncHash.titleTextBox.text
			$syncHash.titleTimerTextBlock.Text = ''
			$syncHash.finalTime = ''

			$runspace = [runspacefactory]::CreateRunspace()
			$powerShell = [powershell]::Create()
			$powerShell.runspace = $runspace
			$runspace.ThreadOptions = 'ReuseThread'
			$runspace.ApartmentState = 'STA'
			$runspace.Open()
			$runspace.SessionStateProxy.SetVariable("syncHash",$syncHash)

			[void]$PowerShell.AddScript({
					$syncHash.watchnumber = $true #Tell if statement in timer to run code

					$result = Measure-Command {
						1..$syncHash.iterations | ForEach-Object {
							$syncHash.watchedNumber = "$_" #Not updating thread here, just updating variable.
						}
					}

					$syncHash.finalTime = "$("{0:N0}" -f $result.TotalMilliseconds) ms" #Format time and again update variable, not UI
					$syncHash.watchnumber = $false		
			})

			#this time we are not saving runspace config for later use, just starting it
			$AsyncObject = $PowerShell.BeginInvoke()

		})
	#EndSection

	#Section Runspace Cleanup
		$syncHash.middleResetButton.add_Click({
			Get-Runspace | Where-Object {$_.RunspaceAvailability -eq 'Available'} | ForEach-Object {$_.dispose()}
		})

		$syncHash.middleReset3Button.add_Click({
			#Wait-Debugger
			If ($syncHash.AsyncObject.isCompleted)
			{
				[void]$syncHash.Powershell.EndInvoke($syncHash.AsyncObject)
				$syncHash.Powershell.runspace.close()
				$syncHash.Powershell.runspace.dispose()
			}
		})
	#EndSection

	$script:syncHash.Window.ShowDialog() | Out-Null
})

$AsyncObject = $PowerShell.BeginInvoke()

