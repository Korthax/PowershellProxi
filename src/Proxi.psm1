param()

if (Get-Module Proxi) {
    return
}

$script:HelpAliases = $('help','-h','--help')

. $PSScriptRoot\ProxiUtils.ps1
. $PSScriptRoot\ProxiHelp.ps1
. $PSScriptRoot\ProxiTabExpansionParams.ps1
. $PSScriptRoot\ProxiTabExpansion.ps1

function Proxi {
<#
.Synopsis
    Usage: proxi [--version] [--help | -h]
           <command> [<args>]

    These are common proxi commands used in various situations:
    help    Shows proxi help options
.Description
    Proxi is a build and deploy tool for really cool people.
#>
    Process
    {
        if($args.Length -eq 0) {
            Write-Proxi-Help
            return
        }

        if($args.Length -eq 1 -and $args[0] -in $script:HelpAliases) {
            Write-Proxi-Help
            return
        }

        if($args | Test-Any { $_ -in $script:HelpAliases } ) {
            $cmd = $args | First-Or-Default { $_ -notin $script:HelpAliases }
            if($cmd) {
                Write-Help $cmd
            }

            return
        }

        $arguments = "";
        foreach($arg in $args[1..($args.Length-1)]) {
            switch -regex ($arg -replace "^$(Get-AliasPattern proxi) ","") {
                "^--(?<param>[^=]+)=(?<value>\S*)$" {
                    $arguments += " -$($matches['param']) $($matches['value'])"
                    break
                }
                "^--(?<param>[^=]+)=(?<value>.+)$" {
                    $arguments += " -$($matches['param']) `"$($matches['value'])`""
                    break
                }
                "^--(?<param>\S*)$" {
                    $arguments += " -$($matches['param'])"
                    break
                }
                "^-(?<shortparam>[^=]+)=(?<value>\S*)$" {
                    $arguments += " -$($matches['shortparam']) $($matches['value'])"
                    break
                }
                "^-(?<shortparam>[^=]+)=(?<value>.+)$" {
                    $arguments += " -$($matches['shortparam']) `"$($matches['value'])`""
                    break
                }
                "^-(?<shortparam>\S*)$" {
                    $arguments += " -$($matches['shortparam'])"
                    break
                }
                default {
                    Write-Host "Dunno: $arg" -ForegroundColor Yellow
                    break
                }
            }
        }

        Write-Host "$($script:ParametersWithValues.Keys)" -ForegroundColor Cyan
        Write-Host "Would run: $($script:scriptFiles[$args[0]])$arguments" -ForegroundColor Red
    }
}

$members = @{
    Function = @(
        'Proxi',
        'TabExpansion',
        'Get-AliasPattern',
        'Test-Administrator'
    )
}

Export-ModuleMember @members