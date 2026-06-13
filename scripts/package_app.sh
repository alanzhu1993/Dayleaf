#!/usr/bin/env bash
#
# package_app.sh — 把 Dayleaf Swift Package 打包成未签名的 Dayleaf.app + Dayleaf.dmg
#
# 仅在 macOS 本地运行（需要 swift / sips / iconutil / hdiutil）。
# 产物输出到 dist/，不签名、不公证，仅用于早期下载测试。
#
# 用法：
#   ./scripts/package_app.sh                 # 使用默认图标源
#   ./scripts/package_app.sh /path/to/icon.png   # 指定图标源 PNG
#
set -euo pipefail

# ---- 基本配置 ----------------------------------------------------------------
APP_NAME="Dayleaf"                 # 用户可见的 App 名
DISPLAY_NAME="Dayleaf"             # CFBundleDisplayName
EXEC_NAME="Dayleaf"                 # Swift executable / product 名，与 Package.swift 一致
BUNDLE_ID="com.alanzhu.dayleaf"
MIN_MACOS="14.0"

# 仓库根目录（脚本在 scripts/ 下）
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

DIST_DIR="$REPO_ROOT/dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
DMG_PATH="$DIST_DIR/$APP_NAME.dmg"
ASSETS_DIR="$REPO_ROOT/Assets"
ICON_SRC_REPO="$ASSETS_DIR/AppIconSource.png"

# 图标源：参数优先 > 仓库内 Assets > 默认 Downloads 路径
DEFAULT_ICON_SRC="$HOME/Downloads/ChatGPT Image 2026年6月13日 14_11_45.png"
ICON_SRC="${1:-}"

# ---- 环境检查 ----------------------------------------------------------------
for tool in swift sips iconutil hdiutil; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "错误：找不到 $tool，请确认在 macOS 上运行并已安装 Xcode / Command Line Tools。" >&2
    exit 1
  fi
done

# ---- 解析图标源 --------------------------------------------------------------
mkdir -p "$ASSETS_DIR"
if [[ -n "$ICON_SRC" ]]; then
  : # 用户显式指定
elif [[ -f "$ICON_SRC_REPO" ]]; then
  ICON_SRC="$ICON_SRC_REPO"
elif [[ -f "$DEFAULT_ICON_SRC" ]]; then
  ICON_SRC="$DEFAULT_ICON_SRC"
else
  echo "错误：找不到图标源 PNG。" >&2
  echo "  请把图标放到 $ICON_SRC_REPO，或运行：./scripts/package_app.sh /path/to/icon.png" >&2
  exit 1
fi

if [[ ! -f "$ICON_SRC" ]]; then
  echo "错误：图标源文件不存在：$ICON_SRC" >&2
  exit 1
fi

# 把图标源固化进仓库，方便复现（若来源不是仓库内文件）
if [[ "$ICON_SRC" != "$ICON_SRC_REPO" ]]; then
  cp "$ICON_SRC" "$ICON_SRC_REPO"
  echo "已复制图标源 -> $ICON_SRC_REPO"
fi
ICON_SRC="$ICON_SRC_REPO"

# ---- 1. 清理并构建 release ---------------------------------------------------
echo "==> 清理 dist/"
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

echo "==> swift build -c release"
swift build -c release

BIN_PATH="$(swift build -c release --show-bin-path)"
EXEC_PATH="$BIN_PATH/$EXEC_NAME"
if [[ ! -x "$EXEC_PATH" ]]; then
  echo "错误：未找到 release 可执行文件：$EXEC_PATH" >&2
  exit 1
fi

# ---- 2. 创建 .app bundle 骨架 ------------------------------------------------
echo "==> 创建 $APP_NAME.app"
MACOS_DIR="$APP_DIR/Contents/MacOS"
RES_DIR="$APP_DIR/Contents/Resources"
mkdir -p "$MACOS_DIR" "$RES_DIR"
cp "$EXEC_PATH" "$MACOS_DIR/$EXEC_NAME"
chmod +x "$MACOS_DIR/$EXEC_NAME"

# ---- 3. 生成 AppIcon.icns ----------------------------------------------------
echo "==> 生成 AppIcon.icns"
ICONSET="$(mktemp -d)/AppIcon.iconset"
mkdir -p "$ICONSET"
# macOS 标准 iconset 尺寸
sips -z 16 16     "$ICON_SRC" --out "$ICONSET/icon_16x16.png"      >/dev/null
sips -z 32 32     "$ICON_SRC" --out "$ICONSET/icon_16x16@2x.png"   >/dev/null
sips -z 32 32     "$ICON_SRC" --out "$ICONSET/icon_32x32.png"      >/dev/null
sips -z 64 64     "$ICON_SRC" --out "$ICONSET/icon_32x32@2x.png"   >/dev/null
sips -z 128 128   "$ICON_SRC" --out "$ICONSET/icon_128x128.png"    >/dev/null
sips -z 256 256   "$ICON_SRC" --out "$ICONSET/icon_128x128@2x.png" >/dev/null
sips -z 256 256   "$ICON_SRC" --out "$ICONSET/icon_256x256.png"    >/dev/null
sips -z 512 512   "$ICON_SRC" --out "$ICONSET/icon_256x256@2x.png" >/dev/null
sips -z 512 512   "$ICON_SRC" --out "$ICONSET/icon_512x512.png"    >/dev/null
sips -z 1024 1024 "$ICON_SRC" --out "$ICONSET/icon_512x512@2x.png" >/dev/null
iconutil -c icns "$ICONSET" -o "$RES_DIR/AppIcon.icns"

# ---- 4. 写 Info.plist --------------------------------------------------------
echo "==> 写 Info.plist"
SHORT_VERSION="${DAYLEAF_VERSION:-0.1.0}"
BUILD_NUMBER="${DAYLEAF_BUILD:-1}"
cat > "$APP_DIR/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$DISPLAY_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleExecutable</key>
    <string>$EXEC_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$SHORT_VERSION</string>
    <key>CFBundleVersion</key>
    <string>$BUILD_NUMBER</string>
    <key>LSMinimumSystemVersion</key>
    <string>$MIN_MACOS</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>MIT License</string>
</dict>
</plist>
PLIST

# 校验 plist 合法性
plutil -lint "$APP_DIR/Contents/Info.plist" >/dev/null

# ---- 5. 生成 .dmg ------------------------------------------------------------
echo "==> 生成 $APP_NAME.dmg"
DMG_STAGE="$(mktemp -d)/dmg"
mkdir -p "$DMG_STAGE"
cp -R "$APP_DIR" "$DMG_STAGE/"
ln -s /Applications "$DMG_STAGE/Applications"
rm -f "$DMG_PATH"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_STAGE" \
  -ov -format UDZO \
  "$DMG_PATH" >/dev/null

# ---- 完成 --------------------------------------------------------------------
echo ""
echo "✅ 打包完成："
echo "   App: $APP_DIR"
echo "   DMG: $DMG_PATH"
echo ""
echo "提示：该 App 未签名、未公证。首次打开请右键 -> 打开，或在系统设置 -> 隐私与安全性 中允许。"
