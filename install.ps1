param([switch]$WhatIf = $false, [switch]$Force = $false, [switch]$Verbose = $false)

if (Get-Module Proxi) {
    Write-Host "Removing module proxi"
    Remove-Module Proxi
}

$installDir = Split-Path $MyInvocation.MyCommand.Path -Parent

if(!$ENV:PROXI_HOME) {
    $ENV:PROXI_HOME = $installDir
    Write-Host "Set PROXI_HOME to $ENV:PROXI_HOME"
}

Import-Module $installDir\src\Proxi.psd1
Write-Host "Imported module at $installDir"
