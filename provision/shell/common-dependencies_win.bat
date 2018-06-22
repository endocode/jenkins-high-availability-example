@echo off


:: NOTE: required because when using the script in this context (vagrant, provisioning, batch), the
:: cmd env does not respect the changed PATH var by chocolaty
call c:\ProgramData\chocolatey\bin\RefreshEnv.cmd


:: set cwd to location of this file
SET DIR=%~dp0


choco install -y curl

:: Disable firewall
netsh advfirewall set privateprofile state off

:: Disable automatic updates
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /v AUOptions /t REG_DWORD /d 0 /f
sc config wuauserv start= disabled
net stop wuauserv
