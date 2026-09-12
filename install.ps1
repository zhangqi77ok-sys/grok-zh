# grok-zh one-command installer (Windows x64)
# Downloads the latest stable Release from JoyElliot/grok-build-Chinese,
# verifies SHA-256, then runs the official in-package installer.
# Compatible with: irm <url> | iex   and   powershell -File install.ps1
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$script:Repo = 'JoyElliot/grok-build-Chinese'
$script:UserAgent = 'grok-zh-install/1.0'
$script:MaxBytes = 536870912L

function Show-GrokZhInstallHelp {
    @'
用法：
  irm https://raw.githubusercontent.com/zhangqi77ok-sys/grok-zh/main/install.ps1 | iex
  powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 [选项]

从 GitHub 正式 Release 安装 Grok Build 中文社区版（grok-zh）。

选项：
  -WithCompatAliases   额外创建 grok / agent 兼容命令（不卸载官方版）
  -NoPathUpdate        不修改用户 PATH
  -Force               允许覆盖缺少归属标记的现有目录
  -InstallDir <路径>   自定义程序目录
  -Help                显示帮助

环境变量（适合 irm | iex）：
  GROK_ZH_WITH_COMPAT=1
  GROK_ZH_NO_PATH=1
  GROK_ZH_FORCE=1
  GROK_ZH_INSTALL_DIR=<路径>
'@ | Write-Host
}

function Get-GrokZhFlag {
    param([string[]]$Names)
    foreach ($arg in $script:CliArgs) {
        foreach ($name in $Names) {
            if ([string]::Equals($arg, $name, [StringComparison]::OrdinalIgnoreCase)) {
                return $true
            }
        }
    }
    return $false
}

function Get-GrokZhOptionValue {
    param([string[]]$Names)
    for ($i = 0; $i -lt $script:CliArgs.Count; $i++) {
        $arg = [string]$script:CliArgs[$i]
        foreach ($name in $Names) {
            if ([string]::Equals($arg, $name, [StringComparison]::OrdinalIgnoreCase)) {
                if ($i + 1 -ge $script:CliArgs.Count) { throw "参数 $name 需要一个路径值。" }
                return [string]$script:CliArgs[$i + 1]
            }
            $prefix = "$name="
            if ($arg.Length -gt $prefix.Length -and $arg.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
                return $arg.Substring($prefix.Length)
            }
        }
    }
    return $null
}

function Assert-GrokZhHttpsGitHub {
    param([uri]$Uri)
    $hosts = @(
        'api.github.com',
        'github.com',
        'release-assets.githubusercontent.com',
        'github-releases.githubusercontent.com',
        'objects.githubusercontent.com'
    )
    $hostName = $Uri.DnsSafeHost.ToLowerInvariant()
    if (!$Uri.IsAbsoluteUri -or $Uri.Scheme -cne 'https' -or $hosts -notcontains $hostName) {
        throw "拒绝非 GitHub HTTPS 地址：$Uri"
    }
}

function Invoke-GrokZhBootstrap {
    $script:CliArgs = @($args)
    if (Get-GrokZhFlag @('-Help', '--help', '-h', '/?')) {
        Show-GrokZhInstallHelp
        return
    }

    $withCompat = (Get-GrokZhFlag @('-WithCompatAliases', '--with-compat-aliases')) -or ($env:GROK_ZH_WITH_COMPAT -eq '1')
    $noPath = (Get-GrokZhFlag @('-NoPathUpdate', '--no-path-update')) -or ($env:GROK_ZH_NO_PATH -eq '1')
    $force = (Get-GrokZhFlag @('-Force', '--force')) -or ($env:GROK_ZH_FORCE -eq '1')
    $installDir = Get-GrokZhOptionValue @('-InstallDir', '--install-dir')
    if ([string]::IsNullOrWhiteSpace($installDir) -and -not [string]::IsNullOrWhiteSpace($env:GROK_ZH_INSTALL_DIR)) {
        $installDir = $env:GROK_ZH_INSTALL_DIR
    }

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    } catch {
    }

    $headers = @{
        'User-Agent' = $script:UserAgent
        'Accept'     = 'application/vnd.github+json'
    }

    Write-Host '正在安装 Grok Build 中文社区版（grok-zh）...'
    $releaseUri = "https://api.github.com/repos/$script:Repo/releases/latest"
    Assert-GrokZhHttpsGitHub ([uri]$releaseUri)
    $release = Invoke-RestMethod -Uri $releaseUri -Headers $headers
    if ($release.prerelease -or $release.draft) {
        throw 'GitHub latest 不是可安装的正式版。'
    }

    $tag = [string]$release.tag_name
    $assets = @($release.assets | Where-Object {
            $_.name -match '^grok-zh-.+-windows-x86_64-gnu\.zip$'
        })
    if ($assets.Count -ne 1) {
        throw 'Release 中没有唯一的 Windows x64 安装包。当前脚本只支持 Windows x64。'
    }
    $asset = $assets[0]
    $name = [string]$asset.name
    $url = [string]$asset.browser_download_url
    Assert-GrokZhHttpsGitHub ([uri]$url)
    if ($url -cnotmatch "^https://github.com/$([regex]::Escape($script:Repo))/releases/download/") {
        throw "附件下载地址不属于 $script:Repo。"
    }

    $expected = $null
    $digest = [string]$asset.digest
    if ($digest -match '^sha256:([0-9a-fA-F]{64})$') {
        $expected = $matches[1].ToLowerInvariant()
    } else {
        $shaUrl = "$url.sha256"
        Assert-GrokZhHttpsGitHub ([uri]$shaUrl)
        $shaText = [string](Invoke-RestMethod -Uri $shaUrl -Headers $headers)
        if ($shaText -notmatch '([0-9a-fA-F]{64})') {
            throw '无法读取安装包 SHA-256。'
        }
        $expected = $matches[1].ToLowerInvariant()
    }

    $size = [long]$asset.size
    if ($size -le 0 -or $size -gt $script:MaxBytes) {
        throw "安装包大小无效：$size"
    }

    Write-Host "版本：$($release.name)  标签：$tag"
    Write-Host ("正在下载 {0} （{1:N1} MiB）..." -f $name, ($size / 1MB))

    $work = Join-Path $env:TEMP ('grok-zh-install-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $work | Out-Null
    $zipPath = Join-Path $work $name
    $extractDir = Join-Path $work 'package'
    try {
        Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $zipPath -Headers @{ 'User-Agent' = $script:UserAgent }
        $actualSize = (Get-Item -LiteralPath $zipPath).Length
        if ($actualSize -ne $size) {
            throw "下载大小与发布信息不一致（$actualSize / $size）。"
        }
        $actual = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($actual -cne $expected) {
            throw 'SHA-256 校验失败，已中止安装。'
        }
        Write-Host 'SHA-256 校验通过。'

        Add-Type -AssemblyName System.IO.Compression
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        New-Item -ItemType Directory -Path $extractDir | Out-Null
        $extractFull = [IO.Path]::GetFullPath($extractDir).TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
        $archive = [IO.Compression.ZipFile]::OpenRead($zipPath)
        try {
            foreach ($entry in $archive.Entries) {
                $relative = $entry.FullName.Replace('/', [IO.Path]::DirectorySeparatorChar)
                $destination = [IO.Path]::GetFullPath((Join-Path $extractDir $relative))
                if (!$destination.StartsWith($extractFull, [StringComparison]::OrdinalIgnoreCase)) {
                    throw "ZIP 包含不安全路径：$($entry.FullName)"
                }
                if ($entry.FullName.EndsWith('/')) {
                    if (!(Test-Path -LiteralPath $destination)) {
                        New-Item -ItemType Directory -Path $destination | Out-Null
                    }
                    continue
                }
                $parent = Split-Path -Parent $destination
                if (!(Test-Path -LiteralPath $parent)) {
                    New-Item -ItemType Directory -Path $parent | Out-Null
                }
                $inputStream = $entry.Open()
                try {
                    $output = [IO.File]::Open($destination, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
                    try { $inputStream.CopyTo($output) }
                    finally { $output.Dispose() }
                } finally {
                    $inputStream.Dispose()
                }
            }
        } finally {
            $archive.Dispose()
        }

        $installer = Get-ChildItem -LiteralPath $extractDir -Recurse -File |
            Where-Object { $_.Name -ceq 'Install-GrokZh.ps1' } |
            Select-Object -First 1
        if (!$installer) {
            throw '安装包缺少 Install-GrokZh.ps1。'
        }

        $ps = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
        $installerArgs = @(
            '-NoProfile',
            '-ExecutionPolicy', 'Bypass',
            '-File', $installer.FullName,
            '-ShowProgress'
        )
        if ($withCompat) { $installerArgs += '-OverrideOfficialCommands' }
        if ($noPath) { $installerArgs += '-NoPathUpdate' }
        if ($force) { $installerArgs += '-Force' }
        if (-not [string]::IsNullOrWhiteSpace($installDir)) {
            $installerArgs += '-InstallDir'
            $installerArgs += $installDir
        }

        Write-Host '正在调用包内安装器...'
        & $ps @installerArgs
        if ($LASTEXITCODE -ne 0) {
            throw "包内安装器退出码：$LASTEXITCODE"
        }

        $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
        $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
        if ($userPath -or $machinePath) {
            $env:Path = @($userPath, $machinePath) -join ';'
        }

        Write-Host ''
        Write-Host '安装完成。重新打开终端后运行：' -ForegroundColor Green
        Write-Host '  grok-zh'
        if ($withCompat) {
            Write-Host '兼容入口已启用，也可以运行：grok'
        }
        Write-Host "项目与更新：https://github.com/$script:Repo"
    } finally {
        if (Test-Path -LiteralPath $work) {
            Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

try {
    Invoke-GrokZhBootstrap @args
} catch {
    $message = "安装未完成：$($_.Exception.GetBaseException().Message)"
    [Console]::Error.WriteLine($message)
    if ($MyInvocation.MyCommand.Path) {
        exit 1
    }
    throw $message
}
