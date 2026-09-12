#!/bin/sh
# grok-zh installer — zhangqi77ok-sys/grok-zh
# Independent macOS/Linux installer: download, verify, deploy, PATH, uninstall.
# curl -fsSL https://raw.githubusercontent.com/zhangqi77ok-sys/grok-zh/main/install.sh | sh
set -eu

REPO='zhangqi77ok-sys/grok-zh'
USER_AGENT='grok-zh/1.0'
MAX_BYTES=536870912
PROGRAM_NAME='install.sh'
DEFAULT_BIN_DIR="${HOME}/.local/bin"
MARKER_NAME='.grok-zh-install-record'

die() {
  printf '%s\n' "${PROGRAM_NAME}: $*" >&2
  exit 1
}

usage() {
  printf '%s\n' \
    'grok-zh 独立安装器（Linux x86_64 / macOS Apple Silicon）' \
    '' \
    '安装：' \
    '  curl -fsSL https://raw.githubusercontent.com/zhangqi77ok-sys/grok-zh/main/install.sh | sh' \
    '' \
    '卸载：' \
    '  curl -fsSL https://raw.githubusercontent.com/zhangqi77ok-sys/grok-zh/main/install.sh | sh -s -- --uninstall' \
    '' \
    '选项：' \
    '  --uninstall             卸载本安装器部署的 grok-zh' \
    '  --version <版本>        安装指定版本，例如 1.0.16' \
    '  --force                 同版本也重新下载安装' \
    '  --with-compat-aliases   额外创建 grok / agent 命令' \
    '  --no-path-update        不改 shell 配置' \
    '  --install-dir <目录>    自定义安装目录' \
    '  -h, --help              显示帮助' \
    '' \
    '环境变量：' \
    '  GROK_ZH_UNINSTALL=1' \
    '  GROK_ZH_VERSION=1.0.16' \
    '  GROK_ZH_FORCE=1'
}

WITH_COMPAT=0
NO_PATH=0
UNINSTALL=0
FORCE=0
REQUESTED_VERSION=${GROK_ZH_VERSION-}
INSTALL_DIR=
INSTALL_DIR_EXPLICIT=0

while [ $# -gt 0 ]; do
  case "$1" in
    --with-compat-aliases) WITH_COMPAT=1 ;;
    --no-path-update) NO_PATH=1 ;;
    --uninstall) UNINSTALL=1 ;;
    --force) FORCE=1 ;;
    --version)
      [ $# -ge 2 ] || die '--version 需要版本号，例如 --version 1.0.16'
      REQUESTED_VERSION=$2
      shift
      ;;
    --install-dir)
      [ $# -ge 2 ] || die '--install-dir 需要目录'
      INSTALL_DIR=$2
      INSTALL_DIR_EXPLICIT=1
      shift
      ;;
    -h|--help) usage; exit 0 ;;
    *) die "未知参数：$1" ;;
  esac
  shift
done

if [ -z "$INSTALL_DIR" ]; then
  if [ -n "${GROK_ZH_INSTALL_DIR-}" ]; then
    INSTALL_DIR=$GROK_ZH_INSTALL_DIR
    INSTALL_DIR_EXPLICIT=1
  else
    INSTALL_DIR=$DEFAULT_BIN_DIR
  fi
fi

[ "${GROK_ZH_WITH_COMPAT-}" = 1 ] && WITH_COMPAT=1
[ "${GROK_ZH_NO_PATH-}" = 1 ] && NO_PATH=1
[ "${GROK_ZH_UNINSTALL-}" = 1 ] && UNINSTALL=1
[ "${GROK_ZH_FORCE-}" = 1 ] && FORCE=1

for required in curl tar uname mktemp mkdir chmod rm mv ln grep tr find head awk tail wc cp; do
  command -v "$required" >/dev/null 2>&1 || die "需要 $required"
done

if command -v sha256sum >/dev/null 2>&1; then
  SHA_CMD='sha256sum'
elif command -v shasum >/dev/null 2>&1; then
  SHA_CMD='shasum -a 256'
else
  die '需要 sha256sum 或 shasum'
fi

os=$(uname -s)
arch=$(uname -m)
case "$os:$arch" in
  Linux:x86_64) PLATFORM='linux-x64'; ARCHIVE_EXT='tar.gz' ;;
  Darwin:arm64) PLATFORM='macos-arm64'; ARCHIVE_EXT='tar.gz' ;;
  Darwin:x86_64) die '暂不提供 Intel Mac 包。请使用 Apple Silicon。' ;;
  *) die "不支持当前系统（$os $arch）。支持 Windows x64、Linux x86_64、macOS Apple Silicon。" ;;
esac

resolve_install_dir() {
  if [ -f "$INSTALL_DIR/grok-zh" ] || [ -f "$(marker_path)" ]; then
    return 0
  fi
  if [ -f "$INSTALL_DIR/bin/grok-zh" ]; then
    printf '%s\n' "检测到旧版安装：$INSTALL_DIR/bin"
    printf '%s\n' '将安装到该目录，避免出现两套 grok-zh。'
    INSTALL_DIR="$INSTALL_DIR/bin"
    return 0
  fi
  if [ "$INSTALL_DIR_EXPLICIT" -eq 0 ] && [ -f "${HOME}/.grok/bin/grok-zh" ]; then
    printf '%s\n' "检测到旧版安装：${HOME}/.grok/bin"
    printf '%s\n' '将安装到该目录，避免出现两套 grok-zh。'
    INSTALL_DIR="${HOME}/.grok/bin"
  fi
}

show_ready() {
  printf '%s\n' "位置：$INSTALL_DIR"
  if [ "$NO_PATH" -eq 1 ]; then
    printf '%s\n' "未修改 PATH。直接运行：$INSTALL_DIR/grok-zh"
  else
    printf '%s\n' '当前窗口可运行：  grok-zh --version'
    printf '%s\n' '若提示找不到命令，请新开一个终端。'
  fi
  if [ "$WITH_COMPAT" -eq 1 ]; then
    printf '%s\n' '兼容入口已启用：  grok'
  fi
  printf '%s\n' "仓库：https://github.com/${REPO}"
}

marker_path() {
  printf '%s\n' "${INSTALL_DIR}/${MARKER_NAME}"
}

do_uninstall() {
  [ -d "$INSTALL_DIR" ] || die "未找到安装目录：$INSTALL_DIR"
  [ -f "$(marker_path)" ] || die "目录缺少本安装器记录，拒绝删除：$INSTALL_DIR"
  printf '%s\n' "正在从 $INSTALL_DIR 卸载 grok-zh ..."
  rm -f "$INSTALL_DIR/grok-zh" "$INSTALL_DIR/agent-zh" "$INSTALL_DIR/grok" "$INSTALL_DIR/agent" "$(marker_path)"
  printf '%s\n' '卸载完成。数据目录 ~/.grok 已保留。'
}

add_path_line() {
  bin_dir=$1
  path_export="export PATH=\"${bin_dir}:\$PATH\""
  case ":${PATH}:" in
    *":${bin_dir}:"*) return 0 ;;
  esac
  shell_name=$(basename "${SHELL:-sh}")
  case "$shell_name" in
    zsh) rc_file="${HOME}/.zshrc" ;;
    bash)
      if [ "$os" = Darwin ]; then rc_file="${HOME}/.bash_profile"
      else rc_file="${HOME}/.bashrc"
      fi
      ;;
    *) rc_file="${HOME}/.profile" ;;
  esac
  if [ -f "$rc_file" ] && grep -F "$bin_dir" "$rc_file" >/dev/null 2>&1; then
    return 0
  fi
  {
    printf '\n%s\n' "# grok-zh  https://github.com/${REPO}"
    printf '%s\n' "$path_export"
  } >> "$rc_file"
  printf '%s\n' "已写入 PATH 到 $rc_file"
}

resolve_install_dir

if [ "$UNINSTALL" -eq 1 ]; then
  do_uninstall
  exit 0
fi

printf '%s\n' '正在安装 grok-zh（独立安装器）...'

if [ -n "$REQUESTED_VERSION" ]; then
  case "$REQUESTED_VERSION" in
    v*) tag=$REQUESTED_VERSION; version=${REQUESTED_VERSION#v} ;;
    *) tag="v$REQUESTED_VERSION"; version=$REQUESTED_VERSION ;;
  esac
  printf '%s\n' "指定版本：$version"
else
  location=$(curl -fsSI -A "$USER_AGENT" "https://github.com/${REPO}/releases/latest" | tr -d '\r' | awk 'tolower($1)=="location:" { print $2 }' | tail -n 1)
  [ -n "$location" ] || die '无法解析 latest 跳转地址。'
  case "$location" in
    https://github.com/*) ;;
    /*) location="https://github.com$location" ;;
    *) die "latest 跳转不在 github.com：$location" ;;
  esac
  tag=${location##*/}
  case "$tag" in
    v*) version=${tag#v} ;;
    *) version=$tag ;;
  esac
fi

archive="grok-zh-${version}-${PLATFORM}.${ARCHIVE_EXT}"
url="https://github.com/${REPO}/releases/download/${tag}/${archive}"

installed_version=
if [ -f "$(marker_path)" ]; then
  installed_version=$(awk -F= '$1=="version" { print $2; exit }' "$(marker_path)")
fi
if [ "$FORCE" -eq 0 ] && [ -n "$installed_version" ] && [ "$installed_version" = "$version" ] && [ -f "$INSTALL_DIR/grok-zh" ]; then
  printf '%s\n' "已经安装 grok-zh $version，跳过下载。"
  printf '%s\n' '需要重装请加 --force，或设置 GROK_ZH_FORCE=1。'
  if [ "$NO_PATH" -eq 0 ]; then
    add_path_line "$INSTALL_DIR"
    export PATH="${INSTALL_DIR}:$PATH"
  fi
  show_ready
  exit 0
fi
if [ -n "$installed_version" ] && [ "$installed_version" != "$version" ]; then
  printf '%s\n' "将从 $installed_version 更新到 $version"
fi

work=$(mktemp -d "${TMPDIR:-/tmp}/grok-zh.XXXXXX") || die '无法创建临时目录。'
cleanup() {
  if [ -n "${work-}" ] && [ -d "$work" ]; then rm -rf "$work"; fi
}
trap cleanup EXIT INT TERM HUP

printf '%s\n' "版本：$version"
printf '%s\n' "平台：$PLATFORM"
printf '%s\n' "正在下载 $archive ..."
curl -fL --retry 3 -A "$USER_AGENT" -o "$work/$archive" "$url"

archive_size=$(wc -c < "$work/$archive" | tr -d ' ')
[ "$archive_size" -gt 0 ] || die '下载的安装包为空。'
[ "$archive_size" -le "$MAX_BYTES" ] || die '安装包超过大小限制。'

curl -fL --retry 3 -A "$USER_AGENT" -o "$work/$archive.sha256" "${url}.sha256" || \
  die '无法下载 SHA-256，已中止。请重试安装。'
expected=$(awk '{ print $1; exit }' "$work/$archive.sha256")
printf '%s\n' "$expected" | grep -Eq '^[0-9a-fA-F]{64}$' || die 'SHA-256 清单格式无效，已中止。'
actual=$($SHA_CMD "$work/$archive" | awk '{ print $1 }')
[ "$expected" = "$actual" ] || die 'SHA-256 校验失败，已中止。请重试安装。'
printf '%s\n' 'SHA-256 校验通过。'

mkdir "$work/pkg"
tar -xzf "$work/$archive" -C "$work/pkg"
binary=$(find "$work/pkg" -type f -name grok-zh | head -n 1)
[ -n "$binary" ] || die '安装包缺少 grok-zh'
chmod +x "$binary"
if [ "$os" = Darwin ]; then
  xattr -cr "$work/pkg" 2>/dev/null || true
fi

mkdir -p "$INSTALL_DIR"
if [ -e "$INSTALL_DIR/grok-zh" ] && [ ! -f "$(marker_path)" ]; then
  die "目标已有 grok-zh，但不是本安装器部署的：$INSTALL_DIR/grok-zh"
fi

tmpbin=$(mktemp "$INSTALL_DIR/.grok-zh.new.XXXXXX") || die '无法创建临时程序文件。'
if ! cp "$binary" "$tmpbin"; then
  rm -f "$tmpbin"
  die '无法写入临时程序文件，旧版未改动。'
fi
chmod 755 "$tmpbin"
if ! "$tmpbin" --version >/dev/null 2>&1; then
  rm -f "$tmpbin"
  die '新程序无法运行，已中止，旧版未改动。'
fi
mv -f "$tmpbin" "$INSTALL_DIR/grok-zh"
chmod 755 "$INSTALL_DIR/grok-zh"
ln -sf grok-zh "$INSTALL_DIR/agent-zh"
if [ "$WITH_COMPAT" -eq 1 ]; then
  ln -sf grok-zh "$INSTALL_DIR/grok"
  ln -sf agent-zh "$INSTALL_DIR/agent"
fi
printf '%s\n' "product=grok-zh" "version=${version}" "dir=${INSTALL_DIR}" > "$(marker_path)"

if [ "$NO_PATH" -eq 0 ]; then
  add_path_line "$INSTALL_DIR"
  export PATH="${INSTALL_DIR}:$PATH"
fi

printf '\n%s\n' "安装完成：$version"
show_ready
