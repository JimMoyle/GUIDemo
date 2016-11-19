<#
.NOTES 
   Author      : Jim Moyle @jimmoyle
   GitHub      : https://github.com/JimMoyle/GUIDemo
	
    Version 0.0.1
#>

#create a file object by listing the contents of a directory
$fileObject = Get-ChildItem c:\GUIDemo
$fileObject

#show what that object is made from
$fileObject | Get-Member


#show the directory property
$fileObject.Directory


#copy the file using its method
$fileObject.CopyTo('C:\GUIDemo\CopyTarget.txt')


#show that there is now 2 files
Get-ChildItem c:\GUIDemo