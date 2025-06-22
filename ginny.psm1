$GinnyModulesPath = "$env:USERPROFILE\Documents\PowerShell\Modules"
$GinnyIndexPath = "$PSScriptRoot\modules\index.json"

function Install-GinnyPackage {
    param (
        [Parameter(Mandatory)]
        [string]$Name
    )

    if (-Not (Test-Path $GinnyIndexPath)) {
        Write-Error "index.json not found at $GinnyIndexPath!"
        return
    }

    $index = Get-Content $GinnyIndexPath | ConvertFrom-Json
    if (-Not $index.$Name) {
        Write-Error "Package '$Name' not found in ginny index."
        return
    }

    $url = $index.$Name.repo
    $moduleFolder = "$GinnyModulesPath\$Name"
    $modulePath = "$moduleFolder\$Name.psm1"

    New-Item -ItemType Directory -Path $moduleFolder -Force | Out-Null
    Write-Host "📥 Downloading $Name from $url..." -ForegroundColor Cyan

    try {
        Invoke-WebRequest -Uri $url -OutFile $modulePath -UseBasicParsing
        Write-Host "✅ Installed '$Name' to $modulePath" -ForegroundColor Green
    } catch {
        Write-Error "❌ Failed to download or install '$Name'."
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

    $path = "$GinnyModulesPath\$Name"
    if (Test-Path $path) {
        Remove-Item -Recurse -Force $path
        Write-Host "🗑️ Uninstalled '$Name'." -ForegroundColor Red
    } else {
        Write-Error "Package '$Name' is not installed."
    }
}

function List-GinnyPackages {
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

# Aliasy
Set-Alias ginny Install-GinnyPackage
Set-Alias ginny-install Install-GinnyPackage
Set-Alias ginny-update Update-GinnyPackage
Set-Alias ginny-uninstall Uninstall-GinnyPackage
Set-Alias ginny-list List-GinnyPackages
Set-Alias ginny-help Show-GinnyHelp
