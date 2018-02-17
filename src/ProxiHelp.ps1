function Write-Proxi-Help() {
    $proxiHelp = (Get-Help Proxi)
    Write-Host $proxiHelp.Description.Text -ForegroundColor Cyan
    Write-Host $proxiHelp.Synopsis
    foreach($command in $script:DefaultCommandsHelp.Keys) {
        $helpItem = $script:DefaultCommandsHelp[$command]

        if($helpItem.GetType() -eq [String]) {
            continue;
        }

        Write-Host "$($command)`t" -NoNewline
        if($helpItem.Synopsis) {
            Write-Host "$($helpItem.Synopsis)"
        } else {
            Write-Host "No Synopsis for this command" -ForegroundColor Red
        }
    }

    Write-Blank-Line
}

function Write-Help([String] $command) {
    $counter = 0

    if(!$script:DefaultCommandsHelp.ContainsKey($command)) {
        Write-Host "Unknown command: '$command'" -ForegroundColor Red
        return
    }

    $helpItem = $script:DefaultCommandsHelp[$command]
    $hasCustomHelp = $helpItem.GetType() -ne [String]

    if($hasCustomHelp -and $helpItem.Synopsis) {
        Write-Host $helpItem.Synopsis -ForegroundColor Cyan
    }

    Write-Host "Usage: proxi $command [--help | -h]"
    if($script:ParameterSwitches.ContainsKey($command)) {
        if($counter % 3 -eq 0) {
            if($counter -gt 0) {
                Write-Blank-Line
            }

            Write-Tab
        }

        foreach($arg in $script:ParameterSwitches[$command]) {
            $hasValue = $script:ParametersWithValues.ContainsKey($command) -and $script:ParametersWithValues[$command].ContainsKey($arg)
            Write-Host "[--$arg" -NoNewline

            if($hasValue){
                Write-Host "=<value>" -NoNewline
            }

            foreach($alias in $script:AliasesByParameter[$command][$arg]) {
                Write-Host " | -$alias" -NoNewline
                
                if($hasValue){
                    Write-Host "=<value>" -NoNewline
                }
            }

            Write-Host "] " -NoNewline
        }

        Write-Blank-Line
    }

    if($hasCustomHelp -and $helpItem.Description.Text) {
        Write-Blank-Line
        Write-Host "$($helpItem.Description.Text)"
    }

    Write-Blank-Line
}

function Write-Blank-Line() {
    Write-Host "`n" -NoNewLine
}

function Write-Tab() {
    Write-Host "`t"  -NoNewline
}