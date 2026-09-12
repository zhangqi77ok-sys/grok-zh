#!/bin/sh
# grok-zh one-command installer (macOS Apple Silicon / Linux x86_64)
# Downloads the latest stable Release from JoyElliot/grok-build-Chinese,
# verifies SHA-256, then runs the official in-package installer.
set -eu

REPO='JoyElliot/grok-build-Chinese'
USER_AGENT='grok-zh-install/1.0'
MAX_BYTES=536870912
PROGRAM_NAME='install.sh'

die() {
  printf '%s\n' "${PROGRAM_NAME}: $*" >&2
  exit 1
}

usage() {
  printf '%s\n' \
    '用法：' \
    '  curl -fsSL https://raw.githubusercontent.com/zhangqi77ok-sys/grok-zh/main/install.sh | sh' \
    '  curl -fsSL https://raw.githubusercontent.com/zhangqi77ok-sys/grok-zh/main/install.sh | sh -s -- [选项]' \
    '  sh install.sh [选项]' \
    '' \
    '从 GitHub 正式 Release 安装 Grok Build 中文社区版（grok-zh）。' \
    '' \
    '选项：' \
    '  --with-compat-aliases  额外创建 grok / agent 兼容命令（不卸载官方版）' \
    '  --no-path-update       不改 shell 配置文件' \
    '  -h, --help             显示帮助' \
    '' \
    '环境变量：' \
    '  GROK_ZH_WITH_COMPAT=1  等同 --with-compat-aliases' \
    '  GROK_ZH_NO_PATH=1      等同 --no-path-update' \
    '  GROK_HOME              数据目录，默认 ~/.grok' \
    '' \
    '支持：Linux x86_64、macOS Apple Silicon。Windows 请用 install.ps1。'
}

WITH_COMPAT=0
NO_PATH=0

for arg in "$@"; do
  case "$arg" in
    --with-compat-aliases) WITH_COMPAT=1 ;;
    --no-path-update) NO_PATH=1 ;;
    -h|--help) usage; exit 0 ;;
    *) die "未知参数：$arg（使用 --help 查看说明）" ;;
  esac
done

[ "${GROK_ZH_WITH_COMPAT-}" = 1 ] && WITH_COMPAT=1
[ "${GROK_ZH_NO_PATH-}" = 1 ] && NO_PATH=1

for required in curl tar uname mktemp awk grep tr wc tail mkdir chmod rm; do
  command -v "$required" >/dev/null 2>&1 || die "需要 $required。"
done

os=$(uname -s)
arch=$(uname -m)
case "$os:$arch" in
  Linux:x86_64) PLATFORM='linux-x86_64-gnu' ;;
  Darwin:arm64) PLATFORM='macos-aarch64' ;;
  Darwin:x86_64)
    die "暂不提供 Intel Mac 安装包。请使用 Apple Silicon，或到 https://github.com/JoyElliot/grok-build-Chinese 从源码构建。"
    ;;
  *)
    die "当前系统不受支持（$os $arch）。已发布包：Windows x64、Linux x86_64、macOS Apple Silicon。"
    ;;
esac

if command -v sha256sum >/dev/null 2>&1; then
  SHA_CMD='sha256sum'
elif command -v shasum >/dev/null 2>&1; then
  SHA_CMD='shasum -a 256'
else
  die "需要 sha256sum 或 shasum。"
fi

github_get() {
  curl -fsSL --retry 3 --retry-delay 1 -A "$USER_AGENT" "$@"
}

github_head() {
  curl -fsSI --retry 3 --retry-delay 1 -A "$USER_AGENT" "$@"
}

printf '%s\n' "正在安装 Grok Build 中文社区版（grok-zh）..."

location=$(github_head "https://github.com/${REPO}/releases/latest" | tr -d '\r' | awk 'tolower($1)=="location:" { print $2 }' | tail -n 1)
[ -n "$location" ] || die "无法解析 GitHub latest 跳转地址。"
case "$location" in
  https://github.com/*) ;;
  /*) location="https://github.com$location" ;;
  *) die "latest 跳转地址不在 github.com：$location" ;;
esac

tag=${location##*/}
case "$tag" in
  release-v[0-9]*) version=${tag#release-v} ;;
  v[0-9]*) version=${tag#v} ;;
  *) die "无法识别发布标签：$tag" ;;
esac
printf '%s\n' "$version" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.]+)?$' || die "版本号无效：$version"

archive="grok-zh-${version}-${PLATFORM}.tar.gz"
download_url="https://github.com/${REPO}/releases/download/${tag}/${archive}"
checksum_url="${download_url}.sha256"

work=$(mktemp -d "${TMPDIR:-/tmp}/grok-zh-install.XXXXXX") || die "无法创建临时目录。"
cleanup() {
  if [ -n "${work-}" ] && [ -d "$work" ]; then
    rm -rf "$work"
  fi
}
trap cleanup EXIT INT TERM HUP

printf '%s\n' "版本：$version"
printf '%s\n' "平台：$PLATFORM"
printf '%s\n' "正在下载 $archive ..."
github_get -o "$work/$archive" "$download_url"
github_get -o "$work/$archive.sha256" "$checksum_url"

archive_size=$(wc -c < "$work/$archive" | tr -d ' ')
[ "$archive_size" -gt 0 ] || die "下载的安装包为空。"
[ "$archive_size" -le "$MAX_BYTES" ] || die "安装包超过大小限制。"

expected=$(awk '{ print $1; exit }' "$work/$archive.sha256")
printf '%s\n' "$expected" | grep -Eq '^[0-9a-fA-F]{64}$' || die "SHA-256 清单格式无效。"
actual=$($SHA_CMD "$work/$archive" | awk '{ print $1 }')
[ "$expected" = "$actual" ] || die "SHA-256 校验失败，已中止安装。"
printf '%s\n' "SHA-256 校验通过。"

members=$(tar -tzf "$work/$archive") || die "无法列出压缩包内容。"
printf '%s\n' "$members" | grep -Eq '(^|/)\.\.(/|$)|^/' && die "压缩包包含不安全路径，已中止。"

pkg_root="grok-zh-${version}-${PLATFORM}"
mkdir "$work/pkg"
tar -xzf "$work/$archive" -C "$work/pkg" || die "解压失败。"
pkg_dir="$work/pkg/$pkg_root"
[ -f "$pkg_dir/Install-GrokZh.sh" ] || die "安装包缺少 Install-GrokZh.sh。"
[ -f "$pkg_dir/grok-zh" ] || die "安装包缺少 grok-zh。"

chmod +x "$pkg_dir/Install-GrokZh.sh" "$pkg_dir/grok-zh" || die "无法设置执行权限。"
if [ "$os" = Darwin ]; then
  xattr -cr "$pkg_dir" 2>/dev/null || true
fi

printf '%s\n' "正在调用包内安装器..."
if [ "$WITH_COMPAT" -eq 1 ]; then
  (CDPATH= cd -- "$pkg_dir" && ./Install-GrokZh.sh --with-compat-aliases)
else
  (CDPATH= cd -- "$pkg_dir" && ./Install-GrokZh.sh)
fi

bin_dir="${GROK_HOME:-$HOME/.grok}/bin"
path_export="export PATH=\"${bin_dir}:\$PATH\""

path_ready=0
case ":${PATH}:" in
  *":${bin_dir}:"*) path_ready=1 ;;
esac

if [ "$NO_PATH" -eq 0 ] && [ "$path_ready" -eq 0 ]; then
  shell_name=$(basename "${SHELL:-sh}")
  case "$shell_name" in
    zsh) rc_file="$HOME/.zshrc" ;;
    bash)
      if [ "$os" = Darwin ]; then
        rc_file="$HOME/.bash_profile"
      else
        rc_file="$HOME/.bashrc"
      fi
      ;;
    *) rc_file="$HOME/.profile" ;;
  esac
  if [ -f "$rc_file" ] && grep -F "$bin_dir" "$rc_file" >/dev/null 2>&1; then
    printf '%s\n' "检测到 $rc_file 已包含 $bin_dir。"
  else
    {
      printf '\n%s\n' "# grok-zh  https://github.com/${REPO}"
      printf '%s\n' "$path_export"
    } >> "$rc_file"
    printf '%s\n' "已写入 PATH 到 $rc_file"
  fi
  export PATH="${bin_dir}:$PATH"
fi

printf '\n%s\n' "安装完成。重新打开终端后运行："
printf '%s\n' "  grok-zh"
if [ "$WITH_COMPAT" -eq 1 ]; then
  printf '%s\n' "兼容入口已启用，也可以运行：grok"
fi
printf '%s\n' "项目与更新：https://github.com/${REPO}"
