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

$thisxml = import-clixml -Path "E:\JimM\Dropbox\Dropbox (Personal)\ScriptScratch\YouTube\Ep3 CheckBoxesAndRadioButtons\CheckBoxesAndRadioButtons\this.xml"

$du = import-clixml -Path "E:\JimM\Dropbox\Dropbox (Personal)\ScriptScratch\YouTube\Ep3 CheckBoxesAndRadioButtons\CheckBoxesAndRadioButtons\\DollarUnderscore.xml"

$thisxml # GUI item properties

$thisxml.Content 

$thisxml.Parent.Name 

$thisxml.Parent.Children

$du #Event Properties