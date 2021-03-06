Function Get-CPUArchitecture
{
IF (($ENV:Processor_Architecture -eq "x86" -AND (Test-Path ENV:PROCESSOR_ARCHITEW6432)) -OR ($ENV:Processor_Architecture -eq "AMD64")) {
Write-Host "Detected 64-bit CPU Architecture"}
ElseIF ($ENV:Processor_Architecture -eq "x86") {
Write-Host "Detected 32-bit CPU Architecture"
} Else {
Write-Host "Unable to determine CPU Architecture"
}
}