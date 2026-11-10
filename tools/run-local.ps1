param([int]$Port = 7864)
$ErrorActionPreference = 'Stop'
$rscriptPath = 'C:/Program Files/R/R-4.5.3/bin/Rscript.exe'
if (-not (Test-Path -LiteralPath $rscriptPath)) { throw 'R 4.5.3 is required. Set rscriptPath to your R 4.5.3 installation.' }
if ($Port -lt 1024 -or $Port -gt 65535) { throw 'Choose a port from 1024 to 65535.' }
Push-Location (Split-Path $PSScriptRoot -Parent)
try { & $rscriptPath -e "shiny::runApp('.',host='127.0.0.1',port=$Port,launch.browser=TRUE)" }
finally { Pop-Location }
