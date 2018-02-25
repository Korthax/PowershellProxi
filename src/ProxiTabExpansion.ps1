$Global:ProxiTabSettings = New-Object PSObject -Property @{
    AllCommands = $false
}

[ProxiSystem] $script:System = [ProxiSystem]::new()
$script:System.loadDefault()

function script:proxiCommands($filter) {
    $cmdList = @()
    $cmdList += $script:System.allCommands() -like "$filter*"
    $cmdList | Sort-Object
}

function script:expandLongParams($cmd, $filter) {
    $script:System.switches()[$cmd] -split ' ' |
        Where-Object { $_ -like "$filter*" } |
        Sort-Object |
        ForEach-Object { 
            if($script:System.parameters()[$cmd].ContainsKey($_)) {
                -join ("--", $_, "=") 
            } else {
                -join ("--", $_) 
            }
        }
}

function script:expandShortParams($cmd, $filter) {
    $script:System.aliases()[$cmd] -split ' ' |
        Where-Object { $_ -like "$filter*" } |
        Sort-Object |
        ForEach-Object  { 
            if($script:System.parameters()[$cmd].ContainsKey($_)) {
                -join ("-", $_, "=") 
            } else {
                -join ("-", $_)
            }
        }
}

function script:expandParamValues($cmd, $param, $filter) {
    $script:System.parameters()[$cmd][$param] -split ' ' |
        Where-Object { $_ -like "$filter*" } |
        Sort-Object |
        ForEach-Object { -join ("--", $param, "=", $_) }
}

if (Test-Path Function:\TabExpansion) {
    Rename-Item Function:\TabExpansion TabExpansionBackup
}

function TabExpansion($line, $lastWord) {
    $lastBlock = [regex]::Split($line, '[|;]')[-1].TrimStart()

    $script:System.loadCurrent()
    $proxiCommandsWithLongParams = $script:System.proxiCommandsWithLongParams()
    $proxiCommandsWithShortParams = $script:System.proxiCommandsWithShortParams()
    $proxiCommandsWithParamValues = $script:System.proxiCommandsWithParamValues()
    
    switch -regex ($lastBlock) {
        "^$(Get-AliasPattern proxi) (.*)" {
            switch -regex ($lastBlock -replace "^$(Get-AliasPattern proxi) ","") {
                # Handles proxi <cmd>
                "^(?<cmd>\S*)$" {
                    proxiCommands $matches['cmd']
                }

                # Handles proxi help <cmd>
                "^help (?<cmd>\S*)$" {
                    proxiCommands $matches['cmd']
                }

                # Handles proxi <cmd> --<param>=<value>
                "^(?<cmd>$proxiCommandsWithParamValues).* --(?<param>[^=]+)=(?<value>\S*)$" {
                    expandParamValues $matches['cmd'] $matches['param'] $matches['value']
                }

                # Handles proxi <cmd> --<param>
                "^(?<cmd>$proxiCommandsWithLongParams).* --(?<param>\S*)$" {
                    expandLongParams $matches['cmd'] $matches['param']
                }
        
                # Handles proxi <cmd> -<shortparam>
                "^(?<cmd>$proxiCommandsWithShortParams).* -(?<shortparam>\S*)$" {
                    expandShortParams $matches['cmd'] $matches['shortparam']
                }
            }
        }
        default {
            if (Test-Path Function:\TabExpansionBackup) {
                TabExpansionBackup $line $lastWord
            }
        }
    }
}