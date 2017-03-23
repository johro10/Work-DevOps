@echo off

if not exist "c:\Wireshark\" mkdir "c:\Wireshark\"

REM if not DEFINED IS_MINIMIZED set IS_MINIMIZED=1 && start "" /min "%~dpnx0" %* REM && exit


start /min "C:\Program Files (x86)\WinPcap\rpcapd.exe"
start /min "wireshark" "C:\Program Files\Wireshark\wireshark.exe" -i "Local Area Connection" -k -b filesize:50000 -w c:\Wireshark\%COMPUTERNAME%.pcapng