@echo off
rem Windows: double-click (status) or run: network\link.cmd up ^| bridge-start ^| status ^| bridge-stop ^| down
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0link.ps1" %*
