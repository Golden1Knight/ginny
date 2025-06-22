$GinnyModulesPath = Join-Path $env:USERPROFILE "Documents\PowerShell\Modules"
$GinnyIndexPath = Join-Path $PSScriptRoot "modules\index.json"

if (-not (Test-Path $GinnyModulesPath)) {
    New-Item -ItemType Directory -Path $GinnyModulesPath -Force | Out-Null
}

function Install-GinnyPackage {
    param (
        [Parameter(Mandatory)]
        [string]$Name
    )

    if (-not (Test-Path $GinnyIndexPath)) {
        Write-Error "index.json not found at $GinnyIndexPath!"
        return
    }

    $index = Get-Content $GinnyIndexPath -Raw | ConvertFrom-Json

    if (-not $index.PSObject.Properties.Name -contains $Name) {
        Write-Error "Package '$Name' not found in ginny index."
        return
    }

    $url = $index.$Name.repo
    $moduleFolder = Join-Path $GinnyModulesPath $Name
    $modulePath = Join-Path $moduleFolder "$Name.psm1"

    if (-not (Test-Path $moduleFolder)) {
        New-Item -ItemType Directory -Path $moduleFolder -Force | Out-Null
    }

    Write-Host "📥 Downloading $Name from $url..." -ForegroundColor Cyan

    try {
        Invoke-WebRequest -Uri $url -OutFile $modulePath -UseBasicParsing
        Write-Host "✅ Installed '$Name' to $modulePath" -ForegroundColor Green
    }
    catch {
        Write-Error "❌ Failed to download or install '$Name'. $_"
    }
}

function Update-GinnyPackage {
    param (
        [Parameter(Mandatory)]
        [string]$Name
    )

    Write-Host "🔄 Updating package '$Name'..." -ForegroundColor Yellow
    Install-GinnyPackage -Name $Name
}

function Uninstall-GinnyPackage {
    param (
        [Parameter(Mandatory)]
        [string]$Name
    )

    $path = Join-Path $GinnyModulesPath $Name

    if (Test-Path $path) {
        Remove-Item -Recurse -Force $path
        Write-Host "🗑️ Uninstalled '$Name'." -ForegroundColor Red
    }
    else {
        Write-Error "Package '$Name' is not installed."
    }
}

function List-GinnyPackages {
    if (-not (Test-Path $GinnyModulesPath)) {
        Write-Host "No packages installed via ginny." -ForegroundColor DarkGray
        return
    }

    $dirs = Get-ChildItem -Directory -Path $GinnyModulesPath

    if ($dirs.Count -eq 0) {
        Write-Host "No packages installed via ginny." -ForegroundColor DarkGray
        return
    }

    Write-Host "`n📦 Installed packages:" -ForegroundColor Green
    foreach ($dir in $dirs) {
        Write-Host " - $($dir.Name)" -ForegroundColor White
    }
}
function Show-GinnyHelp {
    Write-Host @"
🧙‍♀️ Ginny – PowerShell package wizard
──────────────────────────────────────
Commands:
 ginny install NAME      -> install a package
 ginny update  NAME      -> update a package
 ginny uninstall NAME    -> remove a package
 ginny list              -> list installed packages
 ginny help              -> show this help screen
──────────────────────────────────────
"@ -ForegroundColor Magenta
}


function ginny {
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateSet("install", "update", "uninstall", "list", "help")]
        [string]$Command,

        [string]$Name
    )

    switch ($Command) {
        "install"   { 
            if (-not $Name) { Write-Error "Please specify a package name to install."; return }
            Install-GinnyPackage -Name $Name
        }
        "update"    { 
            if (-not $Name) { Write-Error "Please specify a package name to update."; return }
            Update-GinnyPackage -Name $Name
        }
        "uninstall" { 
            if (-not $Name) { Write-Error "Please specify a package name to uninstall."; return }
            Uninstall-GinnyPackage -Name $Name
        }
        "list"      { List-GinnyPackages }
        "help"      { Show-GinnyHelp }
    }
}

# Usuwam wcześniejsze aliasy (jeśli istnieją)
Remove-Item Alias:ginny -ErrorAction SilentlyContinue

# Alias do funkcji głównej
Set-Alias ginny ginny
