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

然后重新打开终端：

```bash
grok-zh
```

## 卸载

```powershell
# Windows
irm https://raw.githubusercontent.com/zhangqi77ok-sys/grok-zh/main/install.ps1 | iex
# 或：
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -Uninstall
```

更简单：运行安装目录里的 `uninstall.cmd`。

```bash
# macOS / Linux
curl -fsSL https://raw.githubusercontent.com/zhangqi77ok-sys/grok-zh/main/install.sh | sh -s -- --uninstall
```

卸载不会删除 `~/.grok` 里的聊天和登录状态。

## 选项

| 作用 | Windows | macOS / Linux |
| --- | --- | --- |
| 同时创建 `grok` 命令 | `$env:GROK_ZH_WITH_COMPAT='1'` | `--with-compat-aliases` |
| 不改 PATH | `$env:GROK_ZH_NO_PATH='1'` | `--no-path-update` |
| 自定义目录 | `$env:GROK_ZH_INSTALL_DIR='D:\apps\grok-zh'` | `--install-dir ~/apps/grok-zh` |

默认安装位置：

- Windows：`%LOCALAPPDATA%\Programs\grok-zh`
- macOS / Linux：`~/.local/bin`

## 脚本会做什么

1. 从 **本仓库** GitHub Release 下载对应系统的安装包
2. SHA-256 校验
3. 写入 `grok-zh`、`agent-zh`
4. 加入 PATH
5. 留下安装记录，方便以后卸载或更新

再执行一次安装命令就是更新。

## 常见问题

**这是官方中文版吗？**  
不是，也不是别人仓库的 fork。这是独立安装器。

**会覆盖官方 grok 吗？**  
默认不会。官方继续用 `grok`，中文版用 `grok-zh`。

**Windows 弹出 SmartScreen？**  
构建未做 Authenticode 签名。请只从本仓库安装。

## 许可证

- 本仓库安装脚本：MIT
- grok-zh 程序：Apache-2.0（SpaceXAI Grok Build）
