Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-RepoInfo {
    $repoUrl = (git config --get remote.origin.url).Trim()
    if ([string]::IsNullOrWhiteSpace($repoUrl)) {
        throw "Could not read remote.origin.url from git config."
    }

    # Thay thế cả dấu '\' và ':' thành '/' để xử lý mượt mà cả HTTP lẫn SSH URLs
    $normalizedUrl = $repoUrl -replace '\\', '/' -replace ':', '/'
    $segments = $normalizedUrl.Split('/', [StringSplitOptions]::RemoveEmptyEntries)
    
    if ($segments.Count -lt 2) {
        throw "Unexpected repository URL format: $repoUrl"
    }

    $repoName = $segments[-1]
    if ($repoName.EndsWith('.git')) {
        $repoName = $repoName.Substring(0, $repoName.Length - 4)
    }

    $repoProject = $segments[-2].ToLowerInvariant()
    $repoNameSlug = $repoName -replace '\.', ''

    return [pscustomobject]@{
        RepoUrl      = $repoUrl
        RepoName     = $repoName
        RepoNameSlug = $repoNameSlug
        RepoProject  = $repoProject
    }
}

function New-RequiredDirectories {
    param(
        [string]$HomeDir,
        [string]$RepoProject,
        [string]$RepoName
    )

    Write-Host "Creating directories mounted in docker for persistent data..."

    $paths = @(
        (Join-Path $HomeDir ".ssh"),
        (Join-Path $HomeDir ".local"),
        (Join-Path $HomeDir ".gnupg"),
        (Join-Path $HomeDir ".$RepoProject/pre-commit-cache"),
        (Join-Path $HomeDir ".$RepoProject/commandhistory.d"),
        (Join-Path $HomeDir ".$RepoProject/commandhistory.d/$RepoName")
    )

    foreach ($path in $paths) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }
}

function New-RequiredFiles {
    param(
        [string]$HomeDir,
        [string]$RepoProject
    )

    Write-Host "Creating files mounted in docker ..."

    $zshHistoryPath = Join-Path $HomeDir ".$RepoProject/zsh-history"
    $gitconfigPath = Join-Path $HomeDir ".gitconfig"
    $netrcPath = Join-Path $HomeDir ".netrc"

    foreach ($path in @($zshHistoryPath, $gitconfigPath, $netrcPath)) {
        if (-not (Test-Path -LiteralPath $path)) {
            New-Item -ItemType File -Path $path -Force | Out-Null
        }
    }

    if (Get-Command chmod -ErrorAction SilentlyContinue) {
        chmod 600 $netrcPath
    }
}

function Get-LinuxId {
    param(
        [string]$Flag,
        [int]$Fallback
    )

    if (Get-Command id -ErrorAction SilentlyContinue) {
        $value = & id $Flag
        if ($LASTEXITCODE -eq 0 -and $value) {
            return $value.Trim()
        }
    }

    return "$Fallback"
}

function Get-HostIp {
    if ((Test-Path -LiteralPath "/etc/hosts") -and (Get-Command awk -ErrorAction SilentlyContinue)) {
        $value = & awk '/wsl-proxy/ {print $1}' /etc/hosts
        if ($LASTEXITCODE -eq 0 -and $value) {
            return $value.Trim()
        }
    }

    return "127.0.0.1"
}

function Set-DockerArgsFile {
    param(
        [string]$EnvFilePath,
        [string]$RepoName,
        [string]$RepoPath,
        [string]$UserName,
        [string]$ContainerUid,
        [string]$ContainerGid,
        [string]$HostIp
    )

    Write-Host "Defining Docker Args ..."

    $content = @(
        "USER=$UserName",
        "HOME=/home/$UserName",
        "REPO_NAME=$RepoName",
        "PROJECT_DIR=$RepoPath",
        "CONTAINER_USER=$UserName",
        "CONTAINER_UID=$ContainerUid",
        "CONTAINER_GID=$ContainerGid",
        "HOST_IP=$HostIp"
    )

    Set-Content -Path $EnvFilePath -Value $content -Encoding utf8
}

try {
    Write-Host "Initialization started..."

    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $devcontainerDir = Split-Path -Parent $scriptDir
    $repoPath = Split-Path -Parent $devcontainerDir
    $envFilePath = Join-Path $devcontainerDir ".env"

    $repoInfo = Get-RepoInfo
    $userName = [Environment]::UserName
    $homeDir = if ($env:HOME) { $env:HOME } else { $env:USERPROFILE }

    if ([string]::IsNullOrWhiteSpace($homeDir)) {
        throw "Could not determine home directory from HOME or USERPROFILE."
    }

    New-RequiredDirectories -HomeDir $homeDir -RepoProject $repoInfo.RepoProject -RepoName $repoInfo.RepoName
    New-RequiredFiles -HomeDir $homeDir -RepoProject $repoInfo.RepoProject

    $containerUid = Get-LinuxId -Flag "-u" -Fallback 1000
    $containerGid = Get-LinuxId -Flag "-g" -Fallback 1000
    $hostIp = Get-HostIp

    # Sử dụng Splatting thay cho backtick để tránh hoàn toàn lỗi cú pháp khi copy
    $dockerArgs = @{
        EnvFilePath  = $envFilePath
        RepoName     = $repoInfo.RepoName
        RepoPath     = $repoPath
        UserName     = $userName
        ContainerUid = $containerUid
        ContainerGid = $containerGid
        HostIp       = $hostIp
    }
    
    Set-DockerArgsFile @dockerArgs

    Write-Host "Initialization completed."
}
catch {
    Write-Error "Error during initialization: $($_.Exception.Message)"
    exit 1
}