<#
.NOTES 
   Author      : Jim Moyle @jimmoyle
   GitHub      : https://github.com/JimMoyle/GUIDemo
	
    Version 0.0.1
#>


#========================================================
#code from previous script
#========================================================


Add-Type -AssemblyName presentationframework, presentationcore
$wpf = @{ }
$inputXML = Get-Content -Path 'C:\Users\Jim\Dropbox (Personal)\E2EVC\PoSH GUI\Source\GUIDemo\GUIDemo\MainWindow.xaml'
$inputXMLClean = $inputXML -replace 'mc:Ignorable="d"','' -replace "x:N",'N' -replace 'x:Class=".*?"','' -replace 'd:DesignHeight="\d*?"','' -replace 'd:DesignWidth="\d*?"',''
[xml]$xaml = $inputXMLClean
$reader = New-Object System.Xml.XmlNodeReader $xaml
$tempform = [Windows.Markup.XamlReader]::Load($reader)
$namedNodes = $xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]") 
$namedNodes | ForEach-Object {$wpf.Add($_.Name, $tempform.FindName($_.Name))}


#========================================================



#========================================================
#Your Code goes here
#========================================================

#Import-Module twitterapi module
Import-Module InvokeTwitterAPIs

$wpf.E2EVCButton.add_Click({

        #Get screen name from textbox
        $screenName = $wpf.E2EVCtextBox.text
		
        $userdata = Get-TwitterUser_Lookup -screen_name $screenName
		$wpf.E2EVCimage.source = $userdata.profile_image_url
		
	})


#===========================================



$wpf.Window.ShowDialog() | Out-Null



