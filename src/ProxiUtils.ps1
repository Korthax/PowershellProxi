function Test-Administrator {
    if (($PSVersionTable.PSVersion.Major -le 5) -or $IsWindows) {
        $currentUser = [Security.Principal.WindowsPrincipal]([Security.Principal.WindowsIdentity]::GetCurrent())
        return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    return 0 -eq (id -u)
}

function Get-AliasPattern($exe) {
    $aliases = @($exe) + @(Get-Alias | Where-Object { $_.Definition -eq $exe } | Select-Object -Exp Name)
    "($($aliases -join '|'))"
}

function Test-Any {
    [CmdletBinding()]
    param(
        $EvaluateCondition,
        [Parameter(ValueFromPipeline = $true)] $ObjectToTest
    )
    begin {
        $any = $false
    }
    process {
        if(& $EvaluateCondition $ObjectToTest) {
            $any = $true
        }
    }
    end {
        $any
    }
}

function First-Or-Default {
    [CmdletBinding()]
    param(
        $EvaluateCondition,
        [Parameter(ValueFromPipeline = $true)] $ObjectToTest
    )
    begin {
        $first = $null
    }
    process {
        if($first -eq $null -and (& $EvaluateCondition $ObjectToTest)) {
            $first = $ObjectToTest
        }
    }
    end {
        $first
    }
}