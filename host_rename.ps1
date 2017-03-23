$computerName = Get-WmiObject Win32_ComputerSystem
$name = Read-Host -Prompt "Please enter the Computer name you want to use."

$computerName.Rename($name)

Restart-Computer -Force