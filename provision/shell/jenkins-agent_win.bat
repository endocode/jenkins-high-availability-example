@echo off

:: NOTE: required because when using the script in this context (vagrant, provisioning, batch), the
:: cmd env does not respect the changed PATH var by chocolaty
call c:\ProgramData\chocolatey\bin\RefreshEnv.cmd


:: set cwd to location of this file
SET DIR=%~dp0


:: importing configuration variables
call "%DIR%\conf.env.bat"



SET SWARM_VERSION=3.13
SET "INSTALL_PATH=c:\Program Files\jenkins-swarm"
SET JAR_LOCATION=%INSTALL_PATH%\swarm-client.jar
SET TASK_FILE=jenkins-swarm-service.bat
SET SERVICE_NAME=jenkins-swarm-task


choco install -y javaruntime --version 8.0.151


mkdir "%INSTALL_PATH%"
:: NOTE: ignore cert. Otherwise it would break, because this old powershell/dotnet version is
:: lacking of newer cert chains
curl --output "%JAR_LOCATION%" --insecure --location --silent "https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/%SWARM_VERSION%/swarm-client-%SWARM_VERSION%.jar"

powershell -Command "(gc %DIR%\%TASK_FILE%_template) -replace 'PRIVATE_NETWORK_SLASH24_PREFIX', '%PRIVATE_NETWORK_SLASH24_PREFIX%' | Out-File -Encoding 'Default'  %DIR%\%TASK_FILE%_template"
copy "%DIR%\%TASK_FILE%_template" "%INSTALL_PATH%\%TASK_FILE%" /y


SCHTASKS /Create ^
         /SC:ONSTART ^
         /TN:%SERVICE_NAME% ^
         /TR:"%INSTALL_PATH%\%TASK_FILE%" ^
         /RL:HIGHEST ^
         /DELAY 0000:08 ^
         /RU "Administrator" ^
         /RP "vagrant" ^
         /F ^
         /NP

SCHTASKS /run /TN:%SERVICE_NAME%
