Get-Service | Where-Object {($_.name -like "SQL*") -or ($_.name -like "MSSQL*")} | Start-Service