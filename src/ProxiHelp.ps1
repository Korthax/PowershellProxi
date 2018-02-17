function Write-Proxi-Help() {
    $proxiHelp = (Get-Help Proxi)
    Write-Host $proxiHelp.Description.Text -ForegroundColor Cyan
    Write-Host $proxiHelp.Synopsis
    foreach($command in $script:Project.HelpByCommand.Keys) {
        $helpItem = $script:Project.HelpByCommand[$command]

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

    if(!$script:Project.HelpByCommand.ContainsKey($command)) {
        Write-Host "Unknown command '$command'" -ForegroundColor Red
        return
    }

    $helpItem = $script:Project.HelpByCommand[$command]
    $hasCustomHelp = $helpItem.GetType() -ne [String]

    if($hasCustomHelp -and $helpItem.Synopsis) {
        Write-Host $helpItem.Synopsis -ForegroundColor Cyan
    }

    Write-Host "Usage: proxi $command [--help | -h]"
    if($script:Project.SwitchesByCommand.ContainsKey($command)) {
        if($counter % 3 -eq 0) {
            if($counter -gt 0) {
                Write-Blank-Line
            }

            Write-Tab
        }

        foreach($arg in $script:Project.SwitchesByCommand[$command]) {
            $hasValue = $script:Project.ParametersByCommand.ContainsKey($command) -and $script:Project.ParametersByCommand[$command].ContainsKey($arg)
            Write-Host "[--$arg" -NoNewline

            if($hasValue){
                Write-Host "=<value>" -NoNewline
            }

            foreach($alias in $script:Project.AliasesByCommandAndParameter[$command][$arg]) {
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