@echo off
setlocal EnableDelayedExpansion

set CONFIG_FILE=%APPDATA%\Battle.net\Battle.net.config
set BATTLE_NET="%ProgramFiles(x86)%\Battle.net\Battle.net Launcher.exe"

if not exist "%CONFIG_FILE%" (
    echo ERROR: Battle.net.config not found
    timeout /t 5 >nul
    exit /b
)

REM === GET ACCOUNTS FROM JSON ===
for /f "delims=" %%A in ('powershell -NoLogo -NoProfile -Command ^
    "(Get-Content '%CONFIG_FILE%' | ConvertFrom-Json).Client.SavedAccountNames"') do (
    set ACCOUNTS=%%A
)

if "%ACCOUNTS%"=="" (
    echo ERROR: No accounts found in config
    timeout /t 5 >nul
    exit /b
)

echo ========================
echo   Battle.net Accounts
echo ========================
echo.

set COUNT=0
for %%A in (%ACCOUNTS:,= %) do (
    set /a COUNT+=1
    echo !COUNT!. %%A
    set ACCOUNT_!COUNT!=%%A
)

:CHOOSE
echo.
set /p SELECTION=Choose account (1-%COUNT%): 
echo %SELECTION%| findstr /R "^[1-%COUNT%]$" >nul || goto CHOOSE

set SELECTED=!ACCOUNT_%SELECTION%!

echo Switching to: %SELECTED%
echo.

REM === REORDER IN BATCH ===
set NEW_ACCOUNTS=%SELECTED%
for %%A in (%ACCOUNTS:,= %) do (
    if /i not "%%A"=="%SELECTED%" (
        set NEW_ACCOUNTS=!NEW_ACCOUNTS!,%%A
    )
)

REM === STOP Battle.net IF RUNNING ===
tasklist | find /i "Battle.net.exe" >nul
if not errorlevel 1 (
    echo Closing Battle.net...
    taskkill /im Battle.net.exe /f >nul
)

echo Updating configuration...

REM === WRITE JSON THROUGH TEMP POWERSHELL SCRIPT ===
set PS_Temp=%TEMP%\_bnet_update.ps1
(
    echo $config = Get-Content '%CONFIG_FILE%' ^| ConvertFrom-Json
    echo $config.Client.SavedAccountNames = "%NEW_ACCOUNTS%"
    echo Copy-Item '%CONFIG_FILE%' '%CONFIG_FILE%.backup' -Force
    echo $config ^| ConvertTo-Json -Depth 100 ^| Out-File '%CONFIG_FILE%' -Encoding UTF8
) > "%PS_Temp%"

powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%PS_Temp%"
del "%PS_Temp%"

echo Launching Battle.net...
start "" %BATTLE_NET%

echo Closing in 5 seconds...
timeout /t 5 >nul
exit /b
