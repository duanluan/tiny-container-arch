#!/bin/sh
# 在 arm64 的 Manjaro 基础镜像里执行一次，把容器初始化成可直接使用的状态。
# 由 Dockerfile 的 RUN 调用；所有参数都来自环境变量（build-arg）。
set -eu

: "${MIRROR:=https://mirrors.tuna.tsinghua.edu.cn/manjaro/arm-stable}"
: "${TZ_NAME:=Asia/Shanghai}"
: "${INSTALL_FONTS:=0}"
: "${INSTALL_XFCE:=0}"

log() { printf '\n==> %s\n' "$*"; }

log "配置 pacman 镜像: $MIRROR"
printf 'Server = %s/$repo/$arch\n' "$MIRROR" > /etc/pacman.d/mirrorlist
pacman -Syy --noconfirm

log "安装基础软件包"
pacman -S --needed --noconfirm \
    sudo bash coreutils procps-ng iproute2 which nano less tar zstd \
    ca-certificates curl wget git

if [ "$INSTALL_FONTS" = "1" ]; then
    log "安装字体"
    pacman -S --needed --noconfirm noto-fonts noto-fonts-cjk ttf-dejavu
fi

if [ "$INSTALL_XFCE" = "1" ]; then
    log "安装 XFCE 桌面、TigerVNC 与 PipeWire"
    pacman -S --needed --noconfirm \
        xfce4 tigervnc dbus polkit \
        pipewire pipewire-pulse wireplumber \
        xorg-xauth xorg-xsetroot xkeyboard-config
fi

. /tmp/common/setup-common.sh

log "创建 tiny 用户（Manjaro 自带 builder，uid 1000）"
setup_user builder

log "安装 sudo / polkit / 导出脚本"
setup_common_files

log "配置 locale / 时区"
setup_locale_tz "$TZ_NAME"

# 注意：Docker 构建/运行时会 bind mount /etc/resolv.conf，这里改不到镜像里。
# 容器的 resolv.conf 由 build.sh 在打包阶段写入。

log "清理构建缓存"
cleanup_image

log "初始化完成"
