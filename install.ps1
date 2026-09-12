# grok-zh installer — zhangqi77ok-sys/grok-zh
# Independent Windows installer: download, verify, deploy, PATH, uninstall.
# irm https://raw.githubusercontent.com/zhangqi77ok-sys/grok-zh/main/install.ps1 | iex
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$script:Repo = 'zhangqi77ok-sys/grok-zh'
$script:UserAgent = 'grok-zh/1.0'
$script:MaxBytes = 536870912L
$script:MarkerName = 'install-record.json'
$script:DefaultDir = Join-Path $env:LOCALAPPDATA 'Programs\grok-zh'

function Show-Help {
    @'
grok-zh 独立安装器（Windows x64）

安装：
  irm https://raw.githubusercontent.com/zhangqi77ok-sys/grok-zh/main/install.ps1 | iex
  powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1

卸载：
  powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -Uninstall

选项：
  -Uninstall             卸载本安装器部署的 grok-zh
  -WithCompatAliases     额外创建 grok.cmd / agent.cmd（不删官方 grok）
  -NoPathUpdate          不修改用户 PATH
  -InstallDir <路径>     自定义安装目录
  -Help                  显示帮助

环境变量：
  GROK_ZH_UNINSTALL=1
  GROK_ZH_WITH_COMPAT=1
  GROK_ZH_NO_PATH=1
  GROK_ZH_INSTALL_DIR=<路径>
'@ | Write-Host
}

function Get-Flag {
    param([string[]]$Names)
    foreach ($arg in $script:CliArgs) {
        foreach ($name in $Names) {
            if ([string]::Equals($arg, $name, [StringComparison]::OrdinalIgnoreCase)) { return $true }
        }
    }
    return $false
}

function Get-OptionValue {
    param([string[]]$Names)
    for ($i = 0; $i -lt $script:CliArgs.Count; $i++) {
        $arg = [string]$script:CliArgs[$i]
        foreach ($name in $Names) {
            if ([string]::Equals($arg, $name, [StringComparison]::OrdinalIgnoreCase)) {
                if ($i + 1 -ge $script:CliArgs.Count) { throw "参数 $name 需要一个值。" }
                return [string]$script:CliArgs[$i + 1]
            }
            $prefix = "$name="
            if ($arg.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
                return $arg.Substring($prefix.Length)
            }
        }
    }
    return $null
}

function Enable-Tls12 {
    try {
        [Net.ServicePointManager]::SecurityProtocol =
            [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    } catch {
    }
}

function Assert-GitHubHttps {
    param([uri]$Uri)
    $allowed = @(
        'api.github.com', 'github.com',
        'release-assets.githubusercontent.com',
        'github-releases.githubusercontent.com',
        'objects.githubusercontent.com'
    )
    if (!$Uri.IsAbsoluteUri -or $Uri.Scheme -cne 'https' -or $allowed -notcontains $Uri.DnsSafeHost.ToLowerInvariant()) {
        throw "拒绝非 GitHub HTTPS 地址：$Uri"
    }
}

function Get-ApiHeaders {
    return @{
        'User-Agent' = $script:UserAgent
        'Accept'     = 'application/vnd.github+json'
    }
}

function Get-DefaultInstallDir {
    $fromEnv = Get-OptionValue @('-InstallDir', '--install-dir')
    if ([string]::IsNullOrWhiteSpace($fromEnv)) { $fromEnv = $env:GROK_ZH_INSTALL_DIR }
    if ([string]::IsNullOrWhiteSpace($fromEnv)) { return $script:DefaultDir }
    return [IO.Path]::GetFullPath($fromEnv)
}

function Get-MarkerPath {
    param([string]$Dir)
    return Join-Path $Dir $script:MarkerName
}

function Read-Marker {
    param([string]$Dir)
    $path = Get-MarkerPath $Dir
    if (!(Test-Path -LiteralPath $path)) { return $null }
    return Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Save-Marker {
    param([string]$Dir, [string]$Version, [string[]]$Commands)
    $record = [ordered]@{
        product    = 'grok-zh'
        version    = $Version
        installDir = $Dir
        commands   = @($Commands)
        time       = [datetime]::UtcNow.ToString('o')
        source     = "https://github.com/$script:Repo"
    }
    $json = $record | ConvertTo-Json -Compress
    [IO.File]::WriteAllText((Get-MarkerPath $Dir), $json, [Text.UTF8Encoding]::new($false))
}

function Add-UserPath {
    param([string]$Dir)
    $current = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ($null -eq $current) { $current = '' }
    $parts = @($current.Split(';') | Where-Object { $_ -and $_.Trim() })
    $already = $false
    foreach ($part in $parts) {
        if ([string]::Equals($part.TrimEnd('\', '/'), $Dir.TrimEnd('\', '/'), [StringComparison]::OrdinalIgnoreCase)) {
            $already = $true
            break
        }
    }
    if (!$already) {
        $newParts = @($Dir) + $parts
        [Environment]::SetEnvironmentVariable('Path', ($newParts -join ';'), 'User')
    }
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $env:Path = @($userPath, $machinePath) -join ';'
}

function Remove-UserPath {
    param([string]$Dir)
    $current = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ($null -eq $current) { return }
    $keep = @()
    foreach ($part in $current.Split(';')) {
        if ([string]::IsNullOrWhiteSpace($part)) { continue }
        if ([string]::Equals($part.TrimEnd('\', '/'), $Dir.TrimEnd('\', '/'), [StringComparison]::OrdinalIgnoreCase)) { continue }
        $keep += $part
    }
    [Environment]::SetEnvironmentVariable('Path', ($keep -join ';'), 'User')
}

function Write-CmdShim {
    param([string]$Path, [string]$Target, [string]$Extra = '')
    $line = if ($Extra) {
        "@echo off`r`n`"%~dp0$Target`" $Extra %*`r`nexit /b %ERRORLEVEL%`r`n"
    } else {
        "@echo off`r`n`"%~dp0$Target`" %*`r`nexit /b %ERRORLEVEL%`r`n"
    }
    [IO.File]::WriteAllText($Path, $line, [Text.UTF8Encoding]::new($false))
}

function Expand-ZipSafe {
    param([string]$ZipPath, [string]$Destination)
    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    $root = [IO.Path]::GetFullPath($Destination).TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
    $archive = [IO.Compression.ZipFile]::OpenRead($ZipPath)
    try {
        foreach ($entry in $archive.Entries) {
            $relative = $entry.FullName.Replace('/', [IO.Path]::DirectorySeparatorChar)
            $dest = [IO.Path]::GetFullPath((Join-Path $Destination $relative))
            if (!$dest.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) {
                throw "压缩包包含不安全路径：$($entry.FullName)"
            }
            if ($entry.FullName.EndsWith('/')) {
                if (!(Test-Path -LiteralPath $dest)) { New-Item -ItemType Directory -Path $dest | Out-Null }
                continue
            }
            $parent = Split-Path -Parent $dest
            if (!(Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent | Out-Null }
            $inputStream = $entry.Open()
            try {
                $output = [IO.File]::Open($dest, [IO.FileMode]::Create, [IO.FileAccess]::Write, [IO.FileShare]::None)
                try { $inputStream.CopyTo($output) }
                finally { $output.Dispose() }
            } finally { $inputStream.Dispose() }
        }
    } finally { $archive.Dispose() }
}

function Find-PackageFile {
    param([string]$Root, [string]$Name)
    $direct = Join-Path $Root $Name
    if (Test-Path -LiteralPath $direct) { return (Get-Item -LiteralPath $direct) }
    return Get-ChildItem -LiteralPath $Root -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ceq $Name } |
        Select-Object -First 1
}

function Invoke-Uninstall {
    param([string]$Dir)
    if (!(Test-Path -LiteralPath $Dir)) {
        Write-Host "未找到安装目录：$Dir"
        return
    }
    $marker = Read-Marker $Dir
    if (!$marker) {
        throw "目录缺少本安装器记录，拒绝删除以免误伤其他文件：$Dir"
    }
    Write-Host "正在卸载 grok-zh $($marker.version) ..."
    Write-Host "目录：$Dir"
    Remove-UserPath $Dir
    Remove-Item -LiteralPath $Dir -Recurse -Force
    Write-Host '卸载完成。聊天记录仍保留在 %USERPROFILE%\.grok' -ForegroundColor Green
}

function Invoke-Install {
    param(
        [string]$Dir,
        [bool]$WithCompat,
        [bool]$NoPath
    )

    Enable-Tls12
    $headers = Get-ApiHeaders
    $releaseUri = "https://api.github.com/repos/$script:Repo/releases/latest"
    Assert-GitHubHttps ([uri]$releaseUri)

    Write-Host '正在安装 grok-zh（独立安装器）...'
    $release = Invoke-RestMethod -Uri $releaseUri -Headers $headers
    if ($release.prerelease -or $release.draft) { throw 'latest 不是正式版。' }

    $assets = @($release.assets | Where-Object {
            $_.name -match '^grok-zh-.+-windows-x64\.zip$'
        })
    if ($assets.Count -ne 1) {
        throw '本仓库 Release 中没有 Windows x64 安装包。请检查 https://github.com/' + $script:Repo + '/releases'
    }
    $asset = $assets[0]
    $name = [string]$asset.name
    $url = [string]$asset.browser_download_url
    Assert-GitHubHttps ([uri]$url)
    if ($url -cnotmatch "^https://github.com/$([regex]::Escape($script:Repo))/releases/download/") {
        throw "下载地址不属于 $script:Repo"
    }

    $expected = $null
    if ([string]$asset.digest -match '^sha256:([0-9a-fA-F]{64})$') {
        $expected = $matches[1].ToLowerInvariant()
    }
    $size = [long]$asset.size
    if ($size -le 0 -or $size -gt $script:MaxBytes) { throw "安装包大小无效：$size" }

    $version = [string]$release.tag_name
    if ($version.StartsWith('v')) { $version = $version.Substring(1) }

    Write-Host "版本：$version"
    Write-Host ("正在下载 {0} （{1:N1} MiB）..." -f $name, ($size / 1MB))

    $work = Join-Path $env:TEMP ('grok-zh-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $work | Out-Null
    try {
        $zipPath = Join-Path $work $name
        Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $zipPath -Headers @{ 'User-Agent' = $script:UserAgent }
        if ((Get-Item -LiteralPath $zipPath).Length -ne $size) { throw '下载大小与发布信息不一致。' }
        if ($expected) {
            $actual = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
            if ($actual -cne $expected) { throw 'SHA-256 校验失败。' }
            Write-Host 'SHA-256 校验通过。'
        }

        $extractDir = Join-Path $work 'pkg'
        Write-Host '正在解压...'
        Expand-ZipSafe -ZipPath $zipPath -Destination $extractDir

        $exe = Find-PackageFile $extractDir 'grok-zh.exe'
        if (!$exe) { throw '安装包缺少 grok-zh.exe' }
        $rg = Find-PackageFile $extractDir 'rg.exe'

        if (Test-Path -LiteralPath $Dir) {
            $existing = Read-Marker $Dir
            if (!$existing) { throw "目标目录已存在且不是本安装器部署的：$Dir" }
        } else {
            New-Item -ItemType Directory -Path $Dir | Out-Null
        }

        Write-Host "正在写入 $Dir"
        Copy-Item -LiteralPath $exe.FullName -Destination (Join-Path $Dir 'grok-zh.exe') -Force
        if ($rg) {
            Copy-Item -LiteralPath $rg.FullName -Destination (Join-Path $Dir 'rg.exe') -Force
        }
        Write-CmdShim (Join-Path $Dir 'agent-zh.cmd') 'grok-zh.exe' 'agent'

        $localUninstallPs1 = @"
`$ErrorActionPreference = 'Stop'
`$dir = Split-Path -Parent `$MyInvocation.MyCommand.Path
`$marker = Join-Path `$dir 'install-record.json'
if (!(Test-Path -LiteralPath `$marker)) { throw "缺少安装记录，拒绝卸载：`$dir" }
`$current = [Environment]::GetEnvironmentVariable('Path', 'User')
if (`$current) {
    `$keep = @(`$current.Split(';') | Where-Object { `$_ -and (`$_.TrimEnd('\','/') -ne `$dir.TrimEnd('\','/')) })
    [Environment]::SetEnvironmentVariable('Path', (`$keep -join ';'), 'User')
}
Remove-Item -LiteralPath `$dir -Recurse -Force
Write-Host '已卸载 grok-zh。数据目录 %USERPROFILE%\.grok 已保留。'
"@
        [IO.File]::WriteAllText((Join-Path $Dir 'uninstall.ps1'), $localUninstallPs1, [Text.UTF8Encoding]::new($false))
        [IO.File]::WriteAllText(
            (Join-Path $Dir 'uninstall.cmd'),
            "@echo off`r`npowershell.exe -NoProfile -ExecutionPolicy Bypass -File `"%~dp0uninstall.ps1`"`r`n",
            [Text.UTF8Encoding]::new($false)
        )

        $commands = @('grok-zh', 'agent-zh')
        if ($WithCompat) {
            Write-CmdShim (Join-Path $Dir 'grok.cmd') 'grok-zh.exe'
            Write-CmdShim (Join-Path $Dir 'agent.cmd') 'grok-zh.exe' 'agent'
            $commands += @('grok', 'agent')
        }

        Save-Marker -Dir $Dir -Version $version -Commands $commands
        if (!$NoPath) { Add-UserPath $Dir }

        $verOut = & (Join-Path $Dir 'grok-zh.exe') --version 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Host '已复制程序，但 --version 未能运行。Windows 可能拦截了未签名程序。' -ForegroundColor Yellow
        } elseif ($verOut) {
            Write-Host ([string]$verOut.Trim())
        }

        Write-Host ''
        Write-Host "安装完成：$version" -ForegroundColor Green
        Write-Host "位置：$Dir"
        Write-Host '请重新打开终端后运行：  grok-zh'
        if ($WithCompat) { Write-Host '兼容入口已启用：  grok' }
        Write-Host "仓库：https://github.com/$script:Repo"
    } finally {
        if (Test-Path -LiteralPath $work) {
            Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

function Main {
    $script:CliArgs = @($args)
    if (Get-Flag @('-Help', '--help', '-h', '/?')) {
        Show-Help
        return
    }
    $dir = Get-DefaultInstallDir
    $uninstall = (Get-Flag @('-Uninstall', '--uninstall')) -or ($env:GROK_ZH_UNINSTALL -eq '1')
    if ($uninstall) {
        Invoke-Uninstall $dir
        return
    }
    $withCompat = (Get-Flag @('-WithCompatAliases', '--with-compat-aliases')) -or ($env:GROK_ZH_WITH_COMPAT -eq '1')
    $noPath = (Get-Flag @('-NoPathUpdate', '--no-path-update')) -or ($env:GROK_ZH_NO_PATH -eq '1')
    Invoke-Install -Dir $dir -WithCompat $withCompat -NoPath $noPath
}

try {
    Main @args
} catch {
    $message = "未完成：$($_.Exception.GetBaseException().Message)"
    [Console]::Error.WriteLine($message)
    if ($MyInvocation.MyCommand.Path) { exit 1 }
    throw $message
}
