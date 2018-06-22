@echo off

SET NEWLINE=^& echo.
SET ETC_HOSTS=%WINDIR%\system32\drivers\etc\hosts



:: NOTE: this is just an example and currently not in use

SET SOME_HOSTNAME=localhost
SET SOME_HOST_IP=127.0.0.1

@echo on
FIND /C /I "%SOME_HOSTNAME%" %ETC_HOSTS%
IF %ERRORLEVEL% NEQ 0 ECHO %NEWLINE%^%SOME_HOST_IP% %SOME_HOSTNAME%>>%ETC_HOSTS%
@echo off

