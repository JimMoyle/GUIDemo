<#
	.NOTES
	===========================================================================
	 Created on:   	2017/03/10
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

	$path = "E:\JimM\Dropbox\Dropbox (Personal)\ScriptScratch\YouTube\Ep6 Routed Events\Ep6 Routed Events"

	$wpf = Get-ChildItem -Path $path -Filter *.xaml -file | Where-Object { $_.Name -ne 'App.xaml' } | Get-XamlObject

	$wpf.WizardWindowFrame.NavigationService.Navigate($wpf.TitlePage) | Out-Null

	$wpf.titleButtonNext.add_Click({

			$wpf.WizardWindowFrame.NavigationService.Navigate($wpf.FinishPage)
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
function Set-IpBoxBehaviour{

    param(
        $OctetEvent
    )

    #Grab content of the textbox
    $octet = $OctetEvent.OriginalSource.text
    
    #If Octet doesn't match numbers or dot replace other characters with nothing
    if ($octet -match '([^\d|\.])')
    {
        $badChar = $matches[1]
        $octet = $octet.Replace($badChar, '')
        $OctetEvent.OriginalSource.CaretIndex = 3
    }
    
    #As long as you aren't in last box then enforce movement to next box under correct conditions
    if (-not ($OctetEvent.OriginalSource.Name -like "*4*")){
        if (($octet -like '*.*' -or $octet.Length -eq 3) -and $octet.Length -gt 1)
        {
            #setup direction object (default value is next so no need to set it)
            $directionNext = new-object System.Windows.Input.FocusNavigationDirection
            #setup traversal object with Next as input
            $requestNext = new-object System.Windows.Input.TraversalRequest $directionNext
            #move focus requires a System.Windows.Input.TraversalRequest object as parameter to change focus to nect object
            $OctetEvent.OriginalSource.MoveFocus($requestNext)
            
        }
    }

    #remove dot from text if it's there
    $octet = $octet.Replace('.', '')
    
    #turn border red if value is > 255
    if ([int]$octet -gt 255)
    {
        $stack = [Windows.Media.VisualTreeHelper]::GetParent($OctetEvent.OriginalSource)
        $border = [Windows.Media.VisualTreeHelper]::GetParent($stack)
        $border.BorderBrush = 'red'
    }
    
    #Walk visual tree to find Border from textbox
    $stack = [Windows.Media.VisualTreeHelper]::GetParent($OctetEvent.OriginalSource)
    $border = [Windows.Media.VisualTreeHelper]::GetParent($stack)
    $currentBorderBrush = $border.BorderBrush

    #check if any of the other octets are simultaneously errored before turning border back to gray
    if ([int]$octet -le 255 -and $currentBorderBrush.color -eq '#FFFF0000')
    {
        #get all child textboxes from stack panel
        $children = $stack.Children
       
       #Include only ones from list which have data
        $childrenoct = $children | where-object { $_.Name -like "*oct*" -and $_.text -ne '' }
        
        if ($childrenoct.count -ge 1)
        {
            
            $childrenoct | ForEach-Object {
                
                $value = $_.text
                if ([int]$value -gt 255)
                {
                    $addValue = 1
                    $totalValue += $addValue
                }
                    
            }
        }
        if ($totalValue -gt 0)
        {
            $border.BorderBrush = 'red'
        }
        else
        {
            $border.BorderBrush = 'gray'
        }
        
    }
    
    #As we have changed the text from what was entered, we now need to set the textbox to the correct txt
    if (-not ($OctetEvent.OriginalSource.text -eq $octet))
    {
        $OctetEvent.OriginalSource.text = $octet
        $OctetEvent.OriginalSource.CaretIndex = 3
    }
} # Episode 5


#Create 'Local' Event for Button one

$wpf.buttonOne.add_Click({

		#Write-Host 'One'

        Write-Host "Local $($_.OriginalSource.Content)"
        
        $_.Handled = $true

	})



#[Windows.EventManager]::GetRoutedEvents() | Where-Object { $_.RoutingStrategy -eq “Bubble”} | Sort-Object Name






#Create Routed event for Button Click attached to Border 

[System.Windows.RoutedEventHandler]$clickHandler = {
			
	write-host "Routed $($_.OriginalSource.Content)"
}

$wpf.titleBorder.AddHandler([System.Windows.Controls.Button]::ClickEvent, $clickHandler)





#Add Routed event for Textbox Text Changed attached to Page

[System.Windows.RoutedEventHandler]$textChangedHandler = {
			
	Set-IpBoxBehaviour -OctetEvent $_
}

$wpf.FinishPage.AddHandler([System.Windows.Controls.TextBox]::TextChangedEvent, $textChangedHandler)



#[Windows.EventManager]::GetRoutedEvents() | Where-Object { $_.RoutingStrategy -eq “Tunnel”} | Sort-Object Name


#Get list of text boxes where we want to implement unrouted event (be careful as this is looking for all textboxes!)
$textBoxes = $wpf.Values | Where-Object {$_ -is [System.Windows.Controls.TextBox] -and $_.IsReadOnly -eq $false -and $_.name -notlike "*1*" } | Select-Object -ExpandProperty Name

#setup direction object
$directionPrevious = new-object System.Windows.Input.FocusNavigationDirection
#set direction to back
$directionPrevious.value__ = 1
#setup traversal object with Next as input
$requestPrevious = new-object System.Windows.Input.TraversalRequest $directionPrevious
#move focus requires a System.Windows.Input.TraversalRequest object as parameter to 'tab' to next object

#Set up Event for all textboxes in list
foreach ($box in $textboxes){
    
    $wpf.$box.add_PreviewKeyDown({
        if ($_.key -eq 'Back' -and $this.CaretIndex -eq 0) { 
            $this.MoveFocus($requestPrevious) 
        } 
     })
}

$wpf.Window.ShowDialog() | Out-Null