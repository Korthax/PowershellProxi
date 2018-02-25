class ProxiSystem {
    [hashtable] $LoadedProjects = @{}
    [hashtable] $ChildProjects = @{}
    [string] $CurrentProject = "default"

    ProxiSystem () {
    }

    [string] getCurrentProjectName() {
        $currentDir = (Get-Item -Path ".\" -Verbose).FullName
        foreach($childProjectName in $this.ChildProjects.keys) {
            if($currentDir.StartsWith($this.ChildProjects[$childProjectName])) {
                return $childProjectName
            }
        }

        return "default"
    }

    [void] loadDefault() {
        [ProxiProject] $defaultProject = [ProxiProject]::new()
        $defaultProject.addCommandsFrom($ENV:PROXI_HOME)
        $this.LoadedProjects.Add('default', $defaultProject)

        foreach($childProject in Get-ChildItem -Path "env:Proxi_Project_*" -ErrorAction SilentlyContinue) {
            $this.ChildProjects.Add(($childProject.Name -replace "Proxi_Project_", ""), $childProject.Value)
            Write-Host "Loaded project: $($childProject.Name)"
        }
    }

    [void] loadCurrent() {
        $childProjectName = $this.getCurrentProjectName()
        $this.CurrentProject = $childProjectName

        if($childProjectName -eq "default") {
            return
        }

        if($this.LoadedProjects.ContainsKey($childProjectName)){
            return
        }

        [ProxiProject] $newProject = [ProxiProject]::new()
        $newProject.addCommandsFrom($this.ChildProjects[$childProjectName])
        $this.LoadedProjects.Add($childProjectName, $newProject)
    }

    [string] scriptFor([string] $command) {
        return $this.LoadedProjects[$this.CurrentProject].ScriptFilesByCommand[$command]
    }

    [array] allCommands() {
        $result = $()
        $result += $this.LoadedProjects["default"].Commands

        if($this.CurrentProject -ne "default") {
            $result += $this.LoadedProjects[$this.CurrentProject].Commands
        }

        return $result
    }

    [hashtable] switches() {
        $result = @{}
        $result += $this.LoadedProjects["default"].SwitchesByCommand

        if($this.CurrentProject -ne "default") {
            foreach($newCommand in $this.LoadedProjects[$this.CurrentProject].SwitchesByCommand.Keys) {
                $value = $this.LoadedProjects[$this.CurrentProject].SwitchesByCommand[$newCommand]
                if($result.ContainsKey($newCommand)) {
                    $result[$newCommand] = $value
                } else {
                    $result.Add($newCommand, $value)
                }
            }
        }

        return $result
    }

    [hashtable] parameters() {
        $result = @{}
        $result += $this.LoadedProjects["default"].ParametersByCommand

        if($this.CurrentProject -ne "default") {
            foreach($newCommand in $this.LoadedProjects[$this.CurrentProject].ParametersByCommand.Keys) {
                $value = $this.LoadedProjects[$this.CurrentProject].ParametersByCommand[$newCommand]
                if($result.ContainsKey($newCommand)) {
                    $result[$newCommand] = $value
                } else {
                    $result.Add($newCommand, $value)
                }
            }
        }

        return $result
    }

    [hashtable] aliases() {
        $result = @{}
        $result += $this.LoadedProjects["default"].AliasesByCommand

        if($this.CurrentProject -ne "default") {
            foreach($newCommand in $this.LoadedProjects[$this.CurrentProject].AliasesByCommand.Keys) {
                $value = $this.LoadedProjects[$this.CurrentProject].AliasesByCommand[$newCommand]
                if($result.ContainsKey($newCommand)) {
                    $result[$newCommand] = $value
                } else {
                    $result.Add($newCommand, $value)
                }
            }
        }

        return $result
    }

    [array] someAliases([string] $command, [string] $parameter) {
        $result = @()

        if($this.LoadedProjects["default"].AliasesByCommandAndParameter.ContainsKey($command) -and $this.LoadedProjects["default"].AliasesByCommandAndParameter[$command].ContainsKey($parameter)) {
            $result += $this.LoadedProjects["default"].AliasesByCommandAndParameter[$command][$parameter]
        }

        if($this.CurrentProject -ne "default" -and $this.LoadedProjects["default"].AliasesByCommandAndParameter.ContainsKey($command) -and $this.LoadedProjects["default"].AliasesByCommandAndParameter[$command].ContainsKey($parameter)) {
            $result += $this.LoadedProjects[$this.CurrentProject].AliasesByCommandAndParameter[$command][$parameter]
        }

        return $result
    }

    [hashtable] help() {
        $result = @{}
        $result += $this.LoadedProjects["default"].HelpByCommand

        if($this.CurrentProject -ne "default") {
            foreach($newCommand in $this.LoadedProjects[$this.CurrentProject].HelpByCommand.Keys) {
                $value = $this.LoadedProjects[$this.CurrentProject].HelpByCommand[$newCommand]
                if($result.ContainsKey($newCommand)) {
                    $result[$newCommand] = $value
                } else {
                    $result.Add($newCommand, $value)
                }
            }
        }

        return $result
    }

    [string] proxiCommandsWithLongParams() {
        return $this.switches().Keys -join '|'
    }

    [string] proxiCommandsWithShortParams() {
        return $this.aliases().Keys -join '|'
    }

    [string] proxiCommandsWithParamValues() {
        return $this.parameters().Keys -join '|'
    }
}
