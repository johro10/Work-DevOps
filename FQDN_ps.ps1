$myFQDN = (Get-WMIObject win32_computersystem).DNSHostName+"."+(Get-WmiObject win32_computersystem).Domain
Write-Host "My HOSTNAME is "$myFQDN