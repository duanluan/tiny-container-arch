#!/usr/bin/env bash
# 构建并签名 Tiny Container Arch 的 Release APK。
#
# 依赖：
#   - JDK 17+
#   - Android SDK（默认 ~/Android/Sdk）
#   - app/src/main/jniLibs/arm64-v8a/ 下的上游预编译库
#
# 签名配置默认读取：
#   ~/.config/tiny-container-arch/keystore.properties
# 可用 KEYSTORE_PROPERTIES 指定其他路径。
set -euo pipefail

cd -- "$(dirname -- "$0")/.."
ROOT="$(pwd)"

SDK="${ANDROID_HOME:-$HOME/Android/Sdk}"
KEYSTORE_PROPS="${KEYSTORE_PROPERTIES:-$HOME/.config/tiny-container-arch/keystore.properties}"
OUT_DIR="$ROOT/app/build/outputs/apk/release"
UNSIGNED="$OUT_DIR/app-release-unsigned.apk"
ALIGNED="$OUT_DIR/app-aligned.apk"
SIGNED="$OUT_DIR/tiny-container-arch.apk"

die() { echo "错误: $*" >&2; exit 1; }

command -v java >/dev/null 2>&1 || die "需要 JDK 17+"
[ -d "$SDK" ] || die "找不到 Android SDK: $SDK"
[ -f "$KEYSTORE_PROPS" ] || die "找不到签名配置: $KEYSTORE_PROPS"
[ -d "$ROOT/app/src/main/jniLibs/arm64-v8a" ] || \
    die "缺少 jniLibs/arm64-v8a（从上游 Releases 下载 jniLibs.zip 解压到 app/src/main/）"

# shellcheck disable=SC1090
. "$KEYSTORE_PROPS"
: "${storeFile:?}" "${storePassword:?}" "${keyAlias:?}" "${keyPassword:?}"

if [ ! -f "$ROOT/local.properties" ]; then
    printf 'sdk.dir=%s\n' "$SDK" > "$ROOT/local.properties"
fi

# 选版本最高的 build-tools
BUILD_TOOLS="$(find "$SDK/build-tools" -maxdepth 1 -mindepth 1 -type d | sort -V | tail -1)"
[ -x "$BUILD_TOOLS/zipalign" ] || die "找不到 zipalign: $BUILD_TOOLS"
[ -x "$BUILD_TOOLS/apksigner" ] || die "找不到 apksigner: $BUILD_TOOLS"

echo "==> Gradle assembleRelease"
"$ROOT/gradlew" -p "$ROOT" assembleRelease

[ -f "$UNSIGNED" ] || die "未找到未签名 APK: $UNSIGNED"

echo "==> zipalign"
"$BUILD_TOOLS/zipalign" -f 4 "$UNSIGNED" "$ALIGNED"

echo "==> apksigner"
"$BUILD_TOOLS/apksigner" sign \
    --ks "$storeFile" \
    --ks-key-alias "$keyAlias" \
    --ks-pass "pass:$storePassword" \
    --key-pass "pass:$keyPassword" \
    --out "$SIGNED" \
    "$ALIGNED"

echo "==> 校验"
"$BUILD_TOOLS/apksigner" verify --verbose "$SIGNED" | sed -n '1,8p'

echo
echo "完成: $SIGNED"
ls -lh "$SIGNED"
