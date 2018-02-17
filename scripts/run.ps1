<#
.Synopsis
    Runs because Steve is the best
#>
[CmdletBinding()]
Param(
    [Parameter(Position = 0, Mandatory = $true)]
    [string] $Name,
    [Parameter(Position = 1, Mandatory = $true)]
    [switch]$BeFast,
    [Alias("SD","Dir")]
    [Parameter(Position = 2, Mandatory = $true)]
    [string]$ScriptDir
)
Process {
    Write-Host "Build" -ForegroundColor Yellow
}