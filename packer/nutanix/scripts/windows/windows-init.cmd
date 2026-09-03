@echo off
setlocal EnableExtensions
rem Finds windows-init.ps1 on any volume (AHV CD-ROMs often have no letter in
rem Get-PSDrive), copies it to disk, and enables WinRM for Packer.
set "DEST=%SystemRoot%\Temp\windows-init.ps1"
set "SRC="

for %%I in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
  if exist "%%I:\windows-init.ps1" (
    set "SRC=%%I:\windows-init.ps1"
    goto :found
  )
)

rem The Packer ISO is labelled PACKER; assign Z: if Windows skipped a letter.
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Get-Volume | Where-Object { $_.FileSystemLabel -eq 'PACKER' -and -not $_.DriveLetter } | ForEach-Object { try { Get-Partition -Volume $_ | Set-Partition -NewDriveLetter Z } catch {} }"
if exist "Z:\windows-init.ps1" set "SRC=Z:\windows-init.ps1"

:found
if not defined SRC (
  echo windows-init.ps1 not found on any drive
  exit /b 1
)

copy /y "%SRC%" "%DEST%" >nul
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%DEST%"
exit /b %ERRORLEVEL%
