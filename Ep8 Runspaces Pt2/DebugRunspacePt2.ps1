#Find PoSH process with the correct 'window title'
Get-PSHostProcessInfo | Where-Object {$_.MainWindowTitle -eq 'MainWindow'} | Enter-PSHostProcess

#Enter the runspace which is waiting for a debugger
Get-Runspace | Where-Object {$_.Debugger.InBreakpoint -eq $true} | Debug-Runspace


Get-Runspace | Where-Object { $_.Id -ne 1 } | ForEach-Object { $_.closeasync() }

Get-Runspace | Where-Object { $_.Id -ne 1 } | ForEach-Object { $_.dispose() }