class ProxiProject
{
    static [Array] $CommonParameters = $("Verbose", "Debug", "ErrorAction", "ErrorVariable", "OutVariable", "OutBuffer", "WarningAction", "InformationAction", "WarningVariable", "InformationVariable", "PipelineVariable")

    [Array] $Commands = @('help')
    [Hashtable] $ScriptFilesByCommand = @{}
    [Hashtable] $HelpByCommand = @{}
    [Hashtable] $SwitchesByCommand = @{}
    [Hashtable] $AliasesByCommand = @{}
    [Hashtable] $AliasesByCommandAndParameter = @{}
    [Hashtable] $ParametersByCommand = @{}

    ProxiProject () {
    }

    [void] addCommandsFrom([string] $path) {
        foreach($scriptFile in Get-ChildItem -Path "$path/scripts" -Filter "*.ps1" -File -ErrorAction SilentlyContinue) {
            $aliases = @()
            $switches = @()
            $parameters = @{}
            $this.AliasesByCommandAndParameter.Add($scriptFile.BaseName, @{})

            $scriptCommand = Get-Command $scriptFile.FullName
            foreach($parameter in $scriptCommand.Parameters.Values) {
                if(!$parameter -or ([ProxiProject]::CommonParameters -contains $parameter.Name)) {
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

                $this.AliasesByCommandAndParameter[$scriptFile.BaseName].Add($parameter.Name, @())
                foreach($alias in $parameter.Aliases) {
                    $aliases += $alias
                    $this.AliasesByCommandAndParameter[$scriptFile.BaseName][$parameter.Name] += $alias
                }

                $switches += $parameter.Name
                if($parameter.SwitchParameter -ne $true) {
                    $parameters.Add($parameter.Name, '')

                    foreach($alias in $aliases) {
                        $parameters.Add($alias, '')
                    }
                }
            }

            $this.Commands += $scriptFile.BaseName
            $this.ScriptFilesByCommand.Add($scriptFile.BaseName, $scriptFile.FullName)
            $this.HelpByCommand.Add($scriptFile.BaseName, (Get-Help $scriptFile.FullName))

            if($switches.Length -gt 0) {
                $this.SwitchesByCommand.Add($scriptFile.BaseName, $switches)
            }
        
            if($aliases.Length -gt 0) {
                $this.AliasesByCommand.Add($scriptFile.BaseName, $aliases)
            }
        
            if($parameters.Count -gt 0) {
                $this.ParametersByCommand.Add($scriptFile.BaseName, $parameters)
            }
        }
    }

    [String] ToString()
    {
        return "Loaded commands: $($this.Commands -join ", ")"
    }
}