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

	$path = "C:\Users\Jim\Dropbox (Personal)\ScriptScratch\YouTube\Ep5 3 ways to do IP address boxes\Ep5 3 Ways To Do IP Address Boxes"

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

#Title Regex Box Code
$wpf.TitleTextBox.Add_TextChanged({
    
    #Regex from Sapien Power Regex
    $ipRegex = '^\b(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b$'

    if($wpf.TitleTextBox.text -match $ipRegex){
        $wpf.TitleBorder.BorderBrush = 'gray'
    }
    else{
        $wpf.TitleBorder.BorderBrush = 'red'
    }

})







#Middle Cast Test code
function Test-IP{
    param (
        $ipaddress
    )
    
    try
    {
        $ipaddress = [ipaddress]$ipaddress
        return $true
    }
    catch
    {
        return $false
    }
}

$wpf.MiddleTextBox.Add_TextChanged({
    
    if($this.text -match $simpleRegex -and (Test-IP -ipaddress $($this.text))){  
        $wpf.MiddleBorder.BorderBrush = 'gray'

    }
    else{
        $wpf.MiddleBorder.BorderBrush = 'red'

    }

})

[regex]$simpleRegex = '\d+\.\d+\.\d+\.\d+'
# $this.text -match $simpleRegex -and (Test-IP -ipaddress $($this.text))








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
}

$wpf.textBoxManIPOct1.Add_TextChanged({
    Set-IpBoxBehaviour -OctetEvent $_
})

$wpf.textBoxManIPOct2.Add_TextChanged({
    Set-IpBoxBehaviour -OctetEvent $_
})

$wpf.textBoxManIPOct3.Add_TextChanged({
    Set-IpBoxBehaviour -OctetEvent $_
})

$wpf.textBoxManIPOct4.Add_TextChanged({
    Set-IpBoxBehaviour -OctetEvent $_
})

#create direction object
$directionPrevious = new-object System.Windows.Input.FocusNavigationDirection
#set direction to back
$directionPrevious.value__ = 1
#create direction request
$requestPrevious = new-object System.Windows.Input.TraversalRequest $directionPrevious

$wpf.textBoxManIPOct2.add_PreviewKeyDown({ if ($_.key -eq 'Back' -and $this.CaretIndex -eq 0) { $this.MoveFocus($requestPrevious) } })
$wpf.textBoxManIPOct3.add_PreviewKeyDown({ if ($_.key -eq 'Back' -and $this.CaretIndex -eq 0) { $this.MoveFocus($requestPrevious) } })
$wpf.textBoxManIPOct4.add_PreviewKeyDown({ if ($_.key -eq 'Back' -and $this.CaretIndex -eq 0) { $this.MoveFocus($requestPrevious) } })


$wpf.Window.Showdialog() | Out-Null #Start Application
