$Global:ProxiTabSettings = New-Object PSObject -Property @{
    AllCommands = $false
}

$script:scriptFiles = @{}
$script:DefaultCommandsHelp = @{}
$script:DefaultCommands = @("help")
$script:ParameterSwitches = @{}
$script:ParameterAliases = @{}
$script:ParametersWithValues = @{}
$script:AliasesByParameter = @{}
$script:CommonParameters = $("Verbose", "Debug", "ErrorAction", "ErrorVariable", "OutVariable", "OutBuffer", "WarningAction", "InformationAction", "WarningVariable", "InformationVariable", "PipelineVariable")

foreach($scriptFile in Get-ChildItem -Path "$ENV:PROXI_HOME/scripts" -Filter "*.ps1" -File -ErrorAction SilentlyContinue) {
    $aliases = @()
    $switches = @()
    $parameters = @{}
    $script:AliasesByParameter.Add($scriptFile.BaseName, @{})

    $scriptCommand = Get-Command $scriptFile.FullName
    foreach($parameter in $scriptCommand.Parameters.Values) {
        if(!$parameter -or ($script:CommonParameters -contains $parameter.Name)) {
            continue
        }

        $valueFromRemainingArguments = $false
        foreach($attribute in $parameter.Attributes) {
            if($attribute.GetType() -eq [Parameter]) {
                $valueFromRemainingArguments = $valueFromRemainingArguments -or $attribute.ValueFromRemainingArguments
            }
        }

        if($valueFromRemainingArguments) {
            continue
        }

        $script:AliasesByParameter[$scriptFile.BaseName].Add($parameter.Name, @())
        foreach($alias in $parameter.Aliases) {
            $aliases += $alias
            $script:AliasesByParameter[$scriptFile.BaseName][$parameter.Name] += $alias
        }
        
        $switches += $parameter.Name
        if($parameter.SwitchParameter -ne $true) {
            $parameters.Add($parameter.Name, '')

            foreach($alias in $aliases) {
                $parameters.Add($alias, '')
            }
        }
    }

    $script:DefaultCommands += $scriptFile.BaseName
    $script:scriptFiles.Add($scriptFile.BaseName, $scriptFile.FullName)
    $script:DefaultCommandsHelp.Add($scriptFile.BaseName, (Get-Help $scriptFile.FullName))

    if($switches.Length -gt 0) {
        $script:ParameterSwitches.Add($scriptFile.BaseName, $switches)
    }

    if($aliases.Length -gt 0) {
        $script:ParameterAliases.Add($scriptFile.BaseName, $aliases)
    }

    if($parameters.Count -gt 0) {
        $script:ParametersWithValues.Add($scriptFile.BaseName, $parameters)
    }
}

$script:proxiCommandsWithLongParams = $script:ParameterSwitches.Keys -join '|'
$script:proxiCommandsWithShortParams = $script:ParameterAliases.Keys -join '|'
$script:proxiCommandsWithParamValues = $script:ParametersWithValues.Keys -join '|'

function script:proxiCommands($filter) {
    $cmdList = @()
    if (-not $global:ProxiTabSettings.AllCommands) {
        $cmdList += $script:DefaultCommands -like "$filter*"
    } else {
        $cmdList += proxi help --all |
            Where-Object { $_ -match '^  \S.*' } |
            ForEach-Object { $_.Split(' ', [StringSplitOptions]::RemoveEmptyEntries) } |
            Where-Object { $_ -like "$filter*" }
    }

    $cmdList | Sort-Object
}

function script:expandLongParams($cmd, $filter) {
    $script:ParameterSwitches[$cmd] -split ' ' |
        Where-Object { $_ -like "$filter*" } |
        Sort-Object |
        ForEach-Object { 
            if($script:ParametersWithValues[$cmd].ContainsKey($_)) {
                -join ("--", $_, "=") 
            } else {
                -join ("--", $_) 
            }
        }
}

function script:expandShortParams($cmd, $filter) {
    $script:ParameterAliases[$cmd] -split ' ' |
        Where-Object { $_ -like "$filter*" } |
        Sort-Object |
        ForEach-Object  { 
            if($script:ParametersWithValues[$cmd].ContainsKey($_)) {
                -join ("-", $_, "=") 
            } else {
                -join ("-", $_)
            }
        }
}

function script:expandParamValues($cmd, $param, $filter) {
    $script:ParametersWithValues[$cmd][$param] -split ' ' |
        Where-Object { $_ -like "$filter*" } |
        Sort-Object |
        ForEach-Object { -join ("--", $param, "=", $_) }
}

if (Test-Path Function:\TabExpansion) {
    Rename-Item Function:\TabExpansion TabExpansionBackup
}

function TabExpansion($line, $lastWord) {
    $lastBlock = [regex]::Split($line, '[|;]')[-1].TrimStart()

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