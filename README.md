# Grok CLI 中文版 · grok-zh

**Grok CLI Chinese / Grok Build 简体中文汉化一键安装。**

把 xAI [Grok Build](https://github.com/xai-org/grok-build)（官方命令 `grok`）装成中文界面。复制一条命令即可，不用翻文档、不用找 Release。

- 命令：`grok-zh`（Grok CLI 中文版）
- 语言：简体中文 `zh-CN`
- 平台：Windows x64、Linux x86_64、macOS Apple Silicon
- 与官方 `grok` 共存，登录和会话共用 `~/.grok`

这不是 SpaceXAI 官方发行版。程序本体来自社区仓库 [JoyElliot/grok-build-Chinese](https://github.com/JoyElliot/grok-build-Chinese)。

[Install](#一条命令安装-grok-cli-中文版) · [English](#grok-cli-chinese-unofficial) · [FAQ](#常见问题) · [Uninstall](#卸载)

---

## 一条命令安装 Grok CLI 中文版

### Windows（PowerShell）

```powershell
irm https://raw.githubusercontent.com/zhangqi77ok-sys/grok-zh/main/install.ps1 | iex
```

也可双击仓库里的 `install.cmd`。

### macOS / Linux

```bash
curl -fsSL https://raw.githubusercontent.com/zhangqi77ok-sys/grok-zh/main/install.sh | sh
```

装好后重新打开终端：

```bash
grok-zh
```

搜这些词都能找到本项目：**Grok 中文**、**Grok CLI 汉化**、**Grok Build 中文版**、**grok-zh**、**Grok CLI Chinese**。

---

## Grok CLI Chinese (unofficial)

One-command installer for the unofficial Simplified Chinese community build of [xAI Grok Build](https://github.com/xai-org/grok-build).

```powershell
# Windows
irm https://raw.githubusercontent.com/zhangqi77ok-sys/grok-zh/main/install.ps1 | iex
```

```bash
# macOS Apple Silicon / Linux x86_64
curl -fsSL https://raw.githubusercontent.com/zhangqi77ok-sys/grok-zh/main/install.sh | sh
```

Then run `grok-zh`. Default UI locale is `zh-CN`. Official `grok` is left in place. Login, sessions, config and plugins stay in `~/.grok`.

Keywords: Grok CLI, Grok Build, grok-zh, Chinese localization, 简体中文, 汉化, xAI, SpaceXAI.

---

## grok-zh 是什么

`grok-zh` 是官方 Grok Build 的非官方简体中文社区版，用来解决英文 TUI 难看懂的问题。

- CLI、终端界面、设置、提示、用户文档默认中文
- 程序名独立为 `grok-zh` / `agent-zh`，默认不覆盖官方 `grok`
- 共用 `~/.grok`：登录、会话、配置、插件、第三方 API 两边一致
- 中文对话里的会话标题和计划优先生成中文
- 内置更新只读社区仓库的 GitHub Immutable Release

当前稳定版对齐上游 **1.0.16**。

| 系统 | 架构 | 安装后命令 |
| --- | --- | --- |
| Windows | x64 | `grok-zh` |
| Linux | x86_64 | `grok-zh` |
| macOS | Apple Silicon (M 系列) | `grok-zh` |

默认安装位置：

- Windows：`%LOCALAPPDATA%\Programs\grok-zh\bin`
- macOS / Linux：`~/.grok/bin`

---

## 安装脚本会做什么

1. 识别当前系统
2. 从 `JoyElliot/grok-build-Chinese` 最新正式 Release 下载安装包
3. SHA-256 校验
4. 调用包内安装器
5. 把 `grok-zh` 加入 PATH（可关闭）

不会默认卸载官方 `grok`，也不会删除 `~/.grok` 数据。

---

## 常用选项

同时创建 `grok` / `agent` 兼容命令（官方版仍保留）：

```powershell
$env:GROK_ZH_WITH_COMPAT='1'; irm https://raw.githubusercontent.com/zhangqi77ok-sys/grok-zh/main/install.ps1 | iex
```

```bash
curl -fsSL https://raw.githubusercontent.com/zhangqi77ok-sys/grok-zh/main/install.sh | sh -s -- --with-compat-aliases
```

不改 PATH：

```powershell
$env:GROK_ZH_NO_PATH='1'; irm https://raw.githubusercontent.com/zhangqi77ok-sys/grok-zh/main/install.ps1 | iex
```

```bash
curl -fsSL https://raw.githubusercontent.com/zhangqi77ok-sys/grok-zh/main/install.sh | sh -s -- --no-path-update
```

本地已克隆时：

```powershell
.\install.cmd
.\install.ps1 -Help
```

```bash
sh install.sh --help
```

---

## 装好以后

```bash
grok-zh --version
cd /path/to/your/project
grok-zh
```

- 未登录时按提示用浏览器登录（数据在 `~/.grok`）
- 默认 `zh-CN`，切回英文：`grok-zh --locale en-US`
- 更新：再跑一次安装命令，或在程序内更新

完整功能说明：[JoyElliot/grok-build-Chinese](https://github.com/JoyElliot/grok-build-Chinese)

---

## 常见问题

**和官方 grok 冲突吗？**  
默认不冲突。官方继续用 `grok`，中文版用 `grok-zh`。

**登录要重新做吗？**  
不用。两边共用 `~/.grok`。

**Intel Mac 能装吗？**  
目前社区包只提供 Apple Silicon。

**Windows 弹出 SmartScreen？**  
社区包没有 Authenticode 签名。请只从本仓库或 `JoyElliot/grok-build-Chinese` 安装。

**这是官方中文版吗？**  
不是。这是社区汉化，不代表 SpaceXAI。

---

## 卸载

- Windows：删除 `%LOCALAPPDATA%\Programs\grok-zh`，并从用户 PATH 去掉该目录
- macOS / Linux：删除 `~/.grok/bin/grok-zh` 与 `~/.grok/bin/agent-zh`
- 聊天记录在 `~/.grok`，卸载程序不会自动删除

---

## 安全说明

- 只从 `github.com` 下载，解压前校验 SHA-256
- Windows 未签名，macOS 未公证
- 模型、登录、订阅仍走官方服务

问题反馈：https://github.com/JoyElliot/grok-build-Chinese/issues

---

## 许可证

- 本仓库安装脚本：MIT
- `grok-zh` 程序：Apache-2.0（上游 SpaceXAI Grok Build 及社区 Fork）
