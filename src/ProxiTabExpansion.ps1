$Global:ProxiTabSettings = New-Object PSObject -Property @{
    AllCommands = $false
}

[ProxiProject] $script:Project = [ProxiProject]::new()
$script:Project.addCommandsFrom($ENV:PROXI_HOME)

$script:ChildProjects = @{}
$script:LoadedProjects = @()


foreach($childProject in Get-ChildItem -Path "env:Proxi_Project_*" -ErrorAction SilentlyContinue) {
    $script:ChildProjects.Add(($childProject.Name -replace "Proxi_Project_", ""), $childProject.Value)
}

Write-Host "Loaded projects; $($script:ChildProjects.Keys -join ", ")"
Write-Host "Loaded projects; $($script:ChildProjects.Values -join ", ")"

$script:proxiCommandsWithLongParams = $script:Project.SwitchesByCommand.Keys -join '|'
$script:proxiCommandsWithShortParams = $script:Project.AliasesByCommand.Keys -join '|'
$script:proxiCommandsWithParamValues = $script:Project.ParametersByCommand.Keys -join '|'

Write-host ($script:Project.ToString())

function script:proxiCommands($filter) {
    $cmdList = @()
    if (-not $global:ProxiTabSettings.AllCommands) {
        $cmdList += $script:Project.Commands -like "$filter*"
    } else {
        $cmdList += proxi help --all |
            Where-Object { $_ -match '^  \S.*' } |
            ForEach-Object { $_.Split(' ', [StringSplitOptions]::RemoveEmptyEntries) } |
            Where-Object { $_ -like "$filter*" }
    }

    $cmdList | Sort-Object
}

function script:expandLongParams($cmd, $filter) {
    $script:Project.SwitchesByCommand[$cmd] -split ' ' |
        Where-Object { $_ -like "$filter*" } |
        Sort-Object |
        ForEach-Object { 
            if($script:Project.ParametersByCommand[$cmd].ContainsKey($_)) {
                -join ("--", $_, "=") 
            } else {
                -join ("--", $_) 
            }
        }
}

function script:expandShortParams($cmd, $filter) {
    $script:Project.AliasesByCommand[$cmd] -split ' ' |
        Where-Object { $_ -like "$filter*" } |
        Sort-Object |
        ForEach-Object  { 
            if($script:Project.ParametersByCommand[$cmd].ContainsKey($_)) {
                -join ("-", $_, "=") 
            } else {
                -join ("-", $_)
            }
        }
}

function script:expandParamValues($cmd, $param, $filter) {
    $script:Project.ParametersByCommand[$cmd][$param] -split ' ' |
        Where-Object { $_ -like "$filter*" } |
        Sort-Object |
        ForEach-Object { -join ("--", $param, "=", $_) }
}

if (Test-Path Function:\TabExpansion) {
    Rename-Item Function:\TabExpansion TabExpansionBackup
}

function TabExpansion($line, $lastWord) {
    $lastBlock = [regex]::Split($line, '[|;]')[-1].TrimStart()

    $modified = $false
    $currentDir = (Get-Item -Path ".\" -Verbose).FullName
    foreach($childProjectName in $script:ChildProjects.keys){
        if($currentDir.StartsWith($script:ChildProjects[$childProjectName]) -and $script:LoadedProjects -notcontains $childProjectName) {
            $script:Project.addCommandsFrom($script:ChildProjects[$childProjectName])
            $script:LoadedProjects += $childProjectName
            $modified = $true
        }
    }

    if($modified) {
        $script:proxiCommandsWithLongParams = $script:Project.SwitchesByCommand.Keys -join '|'
        $script:proxiCommandsWithShortParams = $script:Project.AliasesByCommand.Keys -join '|'
        $script:proxiCommandsWithParamValues = $script:Project.ParametersByCommand.Keys -join '|'
    }

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