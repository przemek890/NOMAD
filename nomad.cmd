@echo off
rem Windows side of ./nomad (same commands): start, stop, status, test [address]. Double-click: start.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0network\link.ps1" %*
