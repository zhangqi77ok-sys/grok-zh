# grok-zh

**Grok CLI 中文版独立安装器。** 自己的仓库、自己的脚本、自己的 Release。

一条命令把 Grok CLI 装成中文界面，不用翻文档。

- 命令：`grok-zh`
- 语言：简体中文
- 系统：Windows x64、Linux x86_64、macOS Apple Silicon
- 与官方 `grok` 共存，登录数据仍在 `~/.grok`

本仓库**不是 fork**。安装、卸载、校验、PATH 都是这里的脚本完成。  
`grok-zh` 程序本身是 SpaceXAI [Grok Build](https://github.com/xai-org/grok-build) 的简体中文构建（Apache-2.0）。

---

## 安装

### Windows

```powershell
irm https://raw.githubusercontent.com/zhangqi77ok-sys/grok-zh/main/install.ps1 | iex
```

或双击 `install.cmd`。

### macOS / Linux

```bash
curl -fsSL https://raw.githubusercontent.com/zhangqi77ok-sys/grok-zh/main/install.sh | sh
```

装完后当前窗口即可运行 `grok-zh --version`。若提示找不到命令，再开一个新终端。

## 卸载

Windows（必须带卸载开关，直接 `irm | iex` 会重新安装）：

```powershell
$env:GROK_ZH_UNINSTALL='1'; irm https://raw.githubusercontent.com/zhangqi77ok-sys/grok-zh/main/install.ps1 | iex
```

或运行安装目录里的 `uninstall.cmd`。

```bash
# macOS / Linux
curl -fsSL https://raw.githubusercontent.com/zhangqi77ok-sys/grok-zh/main/install.sh | sh -s -- --uninstall
```

卸载不会删除 `~/.grok` 里的聊天和登录状态。

## 选项

| 作用 | Windows | macOS / Linux |
| --- | --- | --- |
| 卸载 | `$env:GROK_ZH_UNINSTALL='1'` | `--uninstall` |
| 查看状态 | `$env:GROK_ZH_STATUS='1'` | `--status` |
| 安装指定版本 | `$env:GROK_ZH_VERSION='1.0.16'` | `--version 1.0.16` |
| 同版本强制重装 | `$env:GROK_ZH_FORCE='1'` | `--force` |
| 便携版 | `$env:GROK_ZH_PORTABLE='1'` | `--portable` |
| 便携目录 | `$env:GROK_ZH_PORTABLE_DIR='D:\apps\grok-zh'` | `--portable-dir ~/apps/grok-zh` |
| 同时创建 `grok` 命令 | `$env:GROK_ZH_WITH_COMPAT='1'` | `--with-compat-aliases` |
| 不改 PATH | `$env:GROK_ZH_NO_PATH='1'` | `--no-path-update` |
| 自定义目录 | `$env:GROK_ZH_INSTALL_DIR='D:\apps\grok-zh'` | `--install-dir ~/apps/grok-zh` |

默认安装位置：

- Windows：`%LOCALAPPDATA%\Programs\grok-zh`
- macOS / Linux：`~/.local/bin`

## 脚本会做什么

1. 从 **本仓库** GitHub Release 下载对应系统的安装包
2. 必须通过 SHA-256 校验，否则中止
3. 先在临时目录验证 `grok-zh --version`，再替换旧文件；失败则保留旧版
4. 若发现旧版在 `...\grok-zh\bin` 或 `~/.grok/bin`，自动装到该目录，避免两套并存
5. 写入 `grok-zh`、`agent-zh`，加入 PATH
6. 留下安装记录，方便以后卸载或更新

再执行一次安装命令：版本相同会跳过下载；有新版本才会更新。同版本重装请加 `-Force` / `--force`。

查看是否需要更新（不下载安装包）：

```powershell
$env:GROK_ZH_STATUS='1'; irm https://raw.githubusercontent.com/zhangqi77ok-sys/grok-zh/main/install.ps1 | iex
```

```bash
curl -fsSL https://raw.githubusercontent.com/zhangqi77ok-sys/grok-zh/main/install.sh | sh -s -- --status
```

便携版（不改 PATH，文件夹可拷走）：

```powershell
$env:GROK_ZH_PORTABLE='1'; $env:GROK_ZH_PORTABLE_DIR='D:\apps\grok-zh'; irm https://raw.githubusercontent.com/zhangqi77ok-sys/grok-zh/main/install.ps1 | iex
```

指定版本：

```powershell
$env:GROK_ZH_VERSION='1.0.16'; irm https://raw.githubusercontent.com/zhangqi77ok-sys/grok-zh/main/install.ps1 | iex
```

```bash
curl -fsSL https://raw.githubusercontent.com/zhangqi77ok-sys/grok-zh/main/install.sh | sh -s -- --version 1.0.16
```

## 常见问题

**这是官方中文版吗？**  
不是，也不是别人仓库的 fork。这是独立安装器。

**会覆盖官方 grok 吗？**  
默认不会。官方继续用 `grok`，中文版用 `grok-zh`。

**Windows 弹出 SmartScreen？**  
构建未做 Authenticode 签名。请只从本仓库安装；若弹出拦截，选择「仍要运行」。

**以前装过社区版怎么办？**  
安装器会检测 `%LOCALAPPDATA%\Programs\grok-zh\bin` 或 `~/.grok/bin`，并更新那一套，不会再装一份。

## 许可证

- 本仓库安装脚本：MIT
- grok-zh 程序：Apache-2.0（SpaceXAI Grok Build）
