[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string] $AppVersion
)
Begin {
    $ErrorActionPreference = "Stop"
    $RootDir = (Get-Item (Split-Path -Path $MyInvocation.MyCommand.Definition -Parent)).Parent.FullName
    $Projects = $(Get-ChildItem -Path "$RootDir/src" -Filter "*.csproj" -Recurse -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName })
    $Tests = $(Get-ChildItem -Path "$RootDir/test" -Filter "*Tests.csproj" -Recurse -ErrorAction SilentlyContinue | ForEach-Object { $_.Directory })
}
Process {
    function Run([scriptblock] $scriptBlock) {
        [System.Diagnostics.Stopwatch] $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $scriptBlock.Invoke();
        Write-Host "Completed in $($stopwatch.ElapsedMilliseconds)ms" -ForegroundColor Green
    }

    function Clean() {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        Write-Host "Cleaning..." -ForegroundColor Yellow
        Get-ChildItem $RootDir -include bin,obj,TestResults -Recurse | foreach ($_) { Remove-Item $_.fullname -Force -Recurse -ErrorAction SilentlyContinue }
    }

    function Build() {
        Write-Host "Building Solution..." -ForegroundColor Yellow
        msbuild /t:"Restore;Build" /v:m /m /nologo /p:Version=$AppVersion /p:Configuration=Debug "$RootDir/Catapult.Modules.sln"
    }

    function Test() {
        Write-Host "Running tests..." -ForegroundColor Yellow
        try {
            foreach($testProject in $tests){
                Set-Location $testProject
                dotnet xunit -nobuild -nologo -stoponfail -failskips -usemsbuild -xml "TestResults/TestResult.xml"
            }
        }
        finally {
            Set-Location $RootDir
        }
    }

    function Pack() {
        Write-Host "Creating packages..." -ForegroundColor Yellow
        $projectProperty = $Projects -join '|'
        msbuild /t:Pack /v:m /m /nologo /p:PackageVersion=$AppVersion /p:Configuration=Debug /p:RootDir=$RootDir /p:Projects="$projectProperty" /p:IncludeSymbols=true /p:IncludeSource=true /p:NoBuild=true "$RootDir/msbuild/proxi.csproj"
    }

    $buildTimer = [System.Diagnostics.Stopwatch]::StartNew()
    Write-Host "Startin build..." -ForegroundColor Cyan

    try {
        Run ${function:Clean}
        Run ${function:Build}
        Run ${function:Test}
        Run ${function:Pack}
    }
    finally {
        Write-Host "Build finished in $($buildTimer.ElapsedMilliseconds)" -ForegroundColor Cyan 
    }
}