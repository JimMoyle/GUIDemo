<#
.NOTES 
   Author      : Jim Moyle @jimmoyle
   GitHub      : https://github.com/JimMoyle/GUIDemo
	
    Version 0.0.1
#>

#Add in the frameworks so that we can create the WPF GUI
Add-Type -AssemblyName presentationframework, presentationcore


#Create empty hashtable into which we will place the GUI objects
$wpf = @{ }


#Grab the content of the Visual Studio xaml file as a string
$inputXML = Get-Content -Path 'C:\Users\Jim\Dropbox (Personal)\E2EVC\PoSH GUI\Source\GUIDemo\GUIDemo\MainWindow.xaml'

Clear-Host
$inputXML

Clear-Host
$inputXML | Get-Member


#clean up xml there is syntax which Visual Studio 2015 creates which PoSH can't understand
$inputXMLClean = $inputXML -replace 'mc:Ignorable="d"','' -replace "x:N",'N' -replace 'x:Class=".*?"','' -replace 'd:DesignHeight="\d*?"','' -replace 'd:DesignWidth="\d*?"',''

Clear-Host
$inputXMLClean

			
#change string variable into xml
[xml]$xaml = $inputXMLClean

Clear-Host
$xaml | Get-Member

			
#read xml data into xaml node reader object
$reader = New-Object System.Xml.XmlNodeReader $xaml

#create System.Windows.Window object
$tempform = [Windows.Markup.XamlReader]::Load($reader)

#select each named node.
$namedNodes = $xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]") 

#add all the named nodes as members to the $wpf variable, this also adds in the correct type for the objects.
$namedNodes | ForEach-Object {
	
	$wpf.Add($_.Name, $tempform.FindName($_.Name))
	
}

#show what's inside $wpf
$wpf

Clear-Host
$wpf.E2EVCButton

Clear-Host
$wpf.E2EVCButton | Get-Member

Clear-Host
$buttonEvents = $wpf.E2EVCButton | Get-Member | Where-Object {$_.MemberType -eq 'Event'}
$buttonEvents.count


$wpf.Window.ShowDialog() | Out-Null




