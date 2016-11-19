<#
.NOTES 
   Author      : Jim Moyle @jimmoyle
   GitHub      : https://github.com/JimMoyle/GUIDemo
	
    Version 0.0.1
#>


#import the twitter API module after downloading it from the gallery
Import-Module InvokeTwitterAPIs


#check it is there
Get-Command -Module InvokeTwitterAPIs


#Set screenName variable to the user you want to look up
$screenName = 'JimMoyle'


#Test username lookup
$userdata = Get-TwitterUser_Lookup -screen_name $screenName
$userdata
$userdata.location


#Test location of profile pic
$url = $userdata.profile_image_url
Start-Process $url

