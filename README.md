# grok-zh 一键安装

把 [Grok Build](https://github.com/xai-org/grok-build) 装成中文版。复制一条命令即可，不用再翻文档、找 Release、对校验。

本仓库只提供安装入口。真正的中文程序来自社区版：

**https://github.com/JoyElliot/grok-build-Chinese**

这不是 SpaceXAI 官方发行版。

---

## 一条命令安装

### Windows（PowerShell）

```powershell
irm https://raw.githubusercontent.com/JoyElliot/grok-zh-install/main/install.ps1 | iex
```

也可双击仓库里的 `install.cmd`，或：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

### macOS Apple Silicon / Linux x86_64

```bash
curl -fsSL https://raw.githubusercontent.com/JoyElliot/grok-zh-install/main/install.sh | sh
```

装好后重新打开终端，运行：

```bash
grok-zh
```

---

## grok-zh 是什么

`grok-zh` 是官方 Grok Build（命令 `grok`）的非官方简体中文社区版。

它做了这些事：

- CLI、TUI、设置、提示信息、用户文档默认使用简体中文
- 程序名独立为 `grok-zh` / `agent-zh`，默认与官方 `grok` 共存
- 有意共用 `~/.grok`：登录状态、会话、配置、插件、第三方 API 两边一致
- 中文对话里的会话标题和计划优先生成中文（命令名、路径、工具名、配置键保持原样）
- 内置更新器只读取本社区仓库的 GitHub Immutable Release，不走官方 npm / x.ai 更新源

当前稳定版与上游对齐为 **1.0.16**。已发布平台：

| 系统 | 架构 | 安装后命令 |
| --- | --- | --- |
| Windows | x64 | `grok-zh` |
| Linux | x86_64 | `grok-zh` |
| macOS | Apple Silicon | `grok-zh` |

默认安装位置：

- Windows：`%LOCALAPPDATA%\Programs\grok-zh\bin`
- macOS / Linux：`~/.grok/bin`

---

## 安装脚本会做什么

1. 识别当前系统
2. 从 `JoyElliot/grok-build-Chinese` 的**最新正式 Release** 下载对应安装包
3. 用 GitHub 发布的 SHA-256 校验文件
4. 调用安装包自带的官方安装器完成部署
5. 把 `grok-zh` 加入 PATH（可用选项关闭）

不会：

- 默认卸载官方 `grok`
- 默认接管 `grok` 命令名
- 删除 `~/.grok` 里的聊天记录、登录状态或配置

---

## 常用选项

### 同时创建 `grok` / `agent` 兼容命令

官方版仍保留，只是多个同名入口指向中文版：

```powershell
# Windows（irm | iex 用环境变量）
$env:GROK_ZH_WITH_COMPAT='1'; irm https://raw.githubusercontent.com/JoyElliot/grok-zh-install/main/install.ps1 | iex
```

```bash
# macOS / Linux
curl -fsSL https://raw.githubusercontent.com/JoyElliot/grok-zh-install/main/install.sh | sh -s -- --with-compat-aliases
```

### 不改 PATH

```powershell
$env:GROK_ZH_NO_PATH='1'; irm https://raw.githubusercontent.com/JoyElliot/grok-zh-install/main/install.ps1 | iex
```

```bash
curl -fsSL https://raw.githubusercontent.com/JoyElliot/grok-zh-install/main/install.sh | sh -s -- --no-path-update
```

### 本地已克隆本仓库时

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

- 未登录时按提示用浏览器登录（与官方相同，数据在 `~/.grok`）
- 界面语言默认 `zh-CN`，可用 `grok-zh --locale en-US` 切回英文
- 更新：再执行一次上面的安装命令，或在程序内使用内置更新

更完整的功能说明见社区版仓库：

https://github.com/JoyElliot/grok-build-Chinese

---

## 上传到你自己的 GitHub 仓库

1. 在 GitHub 新建空仓库，例如 `grok-zh-install`（建议 Public）
2. 若仓库名或用户名不是 `JoyElliot/grok-zh-install`，把 `README.md`、`install.ps1`、`install.sh` 里的这一段换成你的地址：

   `JoyElliot/grok-zh-install`

3. 推送：

```bash
cd grok-zh-install
git init
git add .
git commit -m "Add grok-zh one-command installer"
git branch -M main
git remote add origin https://github.com/<你的用户名>/grok-zh-install.git
git push -u origin main
```

4. 把 README 里的两条安装命令发给别人即可。

脚本下载的程序始终来自 `JoyElliot/grok-build-Chinese` 的正式 Release，不依赖你的仓库里有没有二进制。

---

## 安全说明

- Windows 包尚未 Authenticode 签名，首次运行可能出现 SmartScreen，请只从上述 GitHub 仓库安装
- macOS 包尚未 Apple 公证，可能被 Gatekeeper 拦截；安装脚本会尝试去掉下载隔离属性
- 安装脚本只从 `github.com` 下载，并在解压前校验 SHA-256
- 模型、登录、订阅等在线能力仍走官方服务，社区版无法保证

遇到汉化或安装问题：https://github.com/JoyElliot/grok-build-Chinese/issues

---

## 许可证

- 本仓库安装脚本：MIT
- `grok-zh` 程序：Apache-2.0（上游 SpaceXAI Grok Build 及其社区 Fork）
