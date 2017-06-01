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
$inputXML = Get-Content -Path ".\WPFGUIinTenLines\MainWindow.xaml"
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

#Import Twitter Module
Import-Module InvokeTwitterAPIs

#This code runs when the button is clicked
$wpf.YouTubeButton.add_Click({

        #Get screen name from textbox
        $screenName = $wpf.YouTubetextBox.text

        #Get Userdata from Twitter
        $userdata = Get-TwitterUser_Lookup -screen_name $screenName

        #Show user image in GUI
		$wpf.YouTubeimage.source = $userdata.profile_image_url

	})

#=======================================================
#End of Your Code
#=======================================================



$wpf.YouTubeWindow.ShowDialog() | Out-Null