$GinnyModulesPath = "$env:USERPROFILE\Documents\PowerShell\Modules"

function Install-GinnyPackage {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Url
    )

    # Wydobądź nazwę modułu z URL (np. devTools.psm1 => devTools)
    $fileName = [System.IO.Path]::GetFileName($Url)
    if (-not $fileName) {
        Write-Error "Nie można wydobyć nazwy pliku z URL."
        return
    }
    $moduleName = $fileName -replace '\.psm1$', ''

    $moduleFolder = Join-Path $GinnyModulesPath $moduleName
    $modulePath = Join-Path $moduleFolder $fileName

    # Utwórz folder, jeśli nie istnieje
    New-Item -ItemType Directory -Path $moduleFolder -Force | Out-Null

    Write-Host "Pobieranie modułu '$moduleName' z $Url ..." -ForegroundColor Cyan

    try {
        Invoke-WebRequest -Uri $Url -OutFile $modulePath -UseBasicParsing -ErrorAction Stop
        Write-Host "Moduł '$moduleName' został zainstalowany w $modulePath" -ForegroundColor Green
    }
    catch {
        Write-Error "Błąd podczas pobierania lub instalacji modułu: $_"
    }
}

function ginny {
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$Command,

        [Parameter(Position = 1)]
        [string]$Arg
    )

    switch ($Command.ToLower()) {
        'install'   { Install-GinnyPackage -Url $Arg }
        'update'    { Write-Host "Komenda update jest obecnie nieobsługiwana." -ForegroundColor Yellow }
        'uninstall' { 
            $modulePath = Join-Path $GinnyModulesPath $Arg
            if (Test-Path $modulePath) {
                Remove-Item -Recurse -Force $modulePath
                Write-Host "Moduł '$Arg' odinstalowany." -ForegroundColor Red
            } else {
                Write-Error "Moduł '$Arg' nie jest zainstalowany."
            }
        }
        'list'      { 
            if (-not (Test-Path $GinnyModulesPath)) {
                Write-Host "Brak zainstalowanych modułów." -ForegroundColor DarkGray
                return
            }
            $dirs = Get-ChildItem -Directory -Path $GinnyModulesPath
            if ($dirs.Count -eq 0) {
                Write-Host "Brak zainstalowanych modułów." -ForegroundColor DarkGray
                return
            }
            Write-Host "Zainstalowane moduły:" -ForegroundColor Green
            foreach ($dir in $dirs) {
                Write-Host " - $($dir.Name)" -ForegroundColor White
            }
        }
        'help'      {
            Write-Host @"
Ginny - PowerShell package wizard
---------------------------------
Commands:
 ginny install <url>    -> install a module from URL (.psm1)
 ginny uninstall <name> -> uninstall a module by name
 ginny list             -> list installed modules
 ginny help             -> show this help
---------------------------------
"@ -ForegroundColor Magenta
        }
        default { Write-Error "Nieznana komenda: $Command`nUżyj: ginny help" }
    }
}
