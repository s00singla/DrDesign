param([switch]$Reports)
$ErrorActionPreference = 'Stop'
$rscriptPath = 'C:/Program Files/R/R-4.5.3/bin/Rscript.exe'
if (-not (Test-Path -LiteralPath $rscriptPath)) { throw 'R 4.5.3 is required. Set rscriptPath to your R 4.5.3 installation.' }
Push-Location (Split-Path $PSScriptRoot -Parent)
try {
    $testFiles = @('tests/analysis-smoke-tests.R', 'tests/module-audit.R', 'tests/research-module-tests.R', 'tests/scientific-audit.R')
    if ($Reports) { $testFiles += @('tests/report-smoke-tests.R', 'tests/research-report-tests.R', 'tests/export-content-audit.R', 'tests/report-download-tests.R') }
    foreach ($testFile in $testFiles) {
        & $rscriptPath $testFile
        if ($LASTEXITCODE -ne 0) { throw "Check failed: $testFile" }
    }
} finally { Pop-Location }
