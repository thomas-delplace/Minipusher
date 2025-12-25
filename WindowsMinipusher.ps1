# MiniPusher.ps1

# Forcer UTF-8 pour accents
chcp 65001 | Out-Null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Clear-Host

# Couleurs
$yellow = "`e[33m"
$red = "`e[31m"
$green = "`e[32m"
$magenta = "`e[35m"

# Dossier parent où tout sera cloné / git
$baseDir = Split-Path -Parent $PSScriptRoot
Set-Location $baseDir

function PressAnyKey {
    Write-Host "Press any key to continue ..." -ForegroundColor Magenta
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# ===== Fonctions =====

function Install-Dependencies {
    Clear-Host
    Write-Host "=== Install necessary softwares and dependencies ===" -ForegroundColor Yellow

    git --version >$null 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "**Git is not installed !**" -ForegroundColor Yellow
        $resp = Read-Host "Do you want to go to the installation page ? (Y/N)"
        if ($resp -eq "Y") { Start-Process "https://git-scm.com/download/win" }
    } else {
        Write-Host "Git is already installed !" -ForegroundColor Green
    }

    node -v >$null 2>&1
    npm -v >$null 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "**Node.js is not installed !**" -ForegroundColor Yellow
        $resp = Read-Host "Do you want to go to the installation page ? ? (Y/N)"
        if ($resp -eq "Y") { Start-Process "https://nodejs.org/en/download/" }
    } else {
        Write-Host "Node.js is already installed !" -ForegroundColor Green
    }
    PressAnyKey
}

function Configure-User {
    Clear-Host
    Write-Host "=== Git user configuration ===" -ForegroundColor Green

    $currentName = git config --global user.name
    $currentEmail = git config --global user.email

    if ($currentName -or $currentEmail) {
        Write-Host "Git user is already set :" -ForegroundColor Yellow
        Write-Host "  Nom  : $currentName"
        Write-Host "  Email: $currentEmail"
        $confirm = Read-Host "Do you ant to make changes ? (Y/N)"
        if ($confirm -ne "Y") {
            Write-Host "Configuration aborted." -ForegroundColor Yellow
            PressAnyKey
            return
        }
    }

    $username = Read-Host "user name"
    $email = Read-Host "user email"

    # Configuration globale Git
    git config --global user.name "$username"
    git config --global user.email "$email"

    Write-Host "Git user set globally !" -ForegroundColor Yellow
    PressAnyKey
}

function InitOrUpdateRepo {
    Clear-Host
    Write-Host "=== Initialize or update repository ===" -ForegroundColor Green

    $repoFolder = Read-Host "Local folder"
    $destPath = Join-Path $baseDir $repoFolder

    if (Test-Path (Join-Path $destPath ".git")) {
        Write-Host "Repository already exists. Updating ..." -ForegroundColor Yellow
        Push-Location $destPath
        git checkout main
        git pull origin main
        $packageJson = Join-Path $destPath "package.json"
        if (Test-Path $packageJson) {
            Write-Host "package.json found, installing dependencies ..." -ForegroundColor Green
            npm install
            Write-Host "Dependencies installed !" -ForegroundColor Yellow
        }
        Pop-Location
        Write-Host "Repository updated !" -ForegroundColor Yellow
        Write-Host "**Important : Update repo as soon as the changes have been accepted by the system admin !**" -ForegroundColor Red
    } else {
        $url = Read-Host "Enter the url of the repository to clone"
        git clone $url $destPath
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Success : repository cloned into $destPath !" -ForegroundColor Yellow
            $packageJson = Join-Path $destPath "package.json"
            if (Test-Path $packageJson) {
                Write-Host "package.json found, installing dependencies ..." -ForegroundColor Green
                Push-Location $destPath
                npm install
                Pop-Location
                Write-Host "Dependencies installed !" -ForegroundColor Yellow
            }
        } else {
            Write-Host "**Error : cloning canceled !**" -ForegroundColor Red
        }
    }
    PressAnyKey
}

function Send-Modification {
    Clear-Host
    Write-Host "=== Send changes ===" -ForegroundColor Yellow
    $branch = Read-Host "Name for the new branch (has to be unique, no other branch can exist with that name)"
    $message = Read-Host "What have you changed ?"
    git checkout main
    git pull origin main
    git checkout -B $branch
    git add .
    git commit -m "$message"
    git push -u origin $branch
    Write-Host "Changes sent to $branch !" -ForegroundColor Green
    PressAnyKey
}

# ===== Menu interactif avec flèches =====
function Show-Menu {
    param ([string[]]$Options)
    $selected = 0
    while ($true) {
        Clear-Host
        Write-Host "=== Minipusher ===`n" -ForegroundColor Yellow
        for ($i=0; $i -lt $Options.Length; $i++) {
            if ($i -eq $selected) {
                Write-Host " > $($Options[$i])" -ForegroundColor Green
            } else {
                Write-Host "   $($Options[$i])"
            }
        }
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        switch ($key.VirtualKeyCode) {
            38 { if ($selected -gt 0) { $selected-- } } # Up
            40 { if ($selected -lt $Options.Length-1) { $selected++ } } # Down
            13 { return $selected } # Enter
        }
    }
}

# ===== Menu principal =====
$options = @(
    "Send changes",
    "Initialize or update repository",
    "User configuration",
    "Install necessary software and dependencies",
    "Quit"
)

while ($true) {
    $choice = Show-Menu $options
    switch ($choice) {
        0 { Send-Modification }
        1 { InitOrUpdateRepo }
        2 { Configure-User }
        3 { Install-Dependencies }
        4 { break }
    }
}
