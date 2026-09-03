@echo off
setlocal EnableExtensions
rem Locate windows-init.ps1 even when AHV left the Packer CD without a letter.
rem Volume GUID paths (Get-Volume .Path) work without a drive letter.
set "DEST=%SystemRoot%\Temp\windows-init.ps1"
set "LOG=%SystemRoot%\Temp\firstlogon-init.log"

echo windows-init.cmd %DATE% %TIME%>> "%LOG%"

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Get-Volume | ForEach-Object { $c = Join-Path $_.Path 'windows-init.ps1'; if (Test-Path -LiteralPath $c) { Copy-Item -LiteralPath $c $env:SystemRoot\Temp\windows-init.ps1 -Force; Add-Content $env:SystemRoot\Temp\firstlogon-init.log $c } }"

if not exist "%DEST%" (
  echo windows-init.ps1 not found>> "%LOG%"
  exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%DEST%"
exit /b %ERRORLEVEL%
