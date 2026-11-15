# Tiny Container Arch Linux ARM 容器构建套件

给 [Tiny Container](../README.md) 生成可导入的 `rootfs.tar.zst`，基底是
**Arch Linux ARM（aarch64）**。

> App 本身与发行版无关。发行版相关的内容全部在容器镜像里，这个目录不改 App 代码。

## 为什么用 Arch 而不是 Manjaro

2026-11 实测：

| | Manjaro ARM | Arch Linux ARM |
| --- | --- | --- |
| 仓库状态 | stable/testing/unstable 全部停在 2025-09 | core/extra 当天仍在更新 |
| glibc | 2.35（2022 年） | 2.43 |
| Firefox | 123 | 160 |
| PipeWire | 1.0.3 | 1.6.11 |
| TigerVNC | 1.13 | 1.16 |
| XFCE | 4.18 | 4.20 |

Manjaro ARM 的仓库实际已停更，新软件经常因为 glibc 太老而无法启动，
也没有安全更新。因此这个套件只保留 Arch Linux ARM。

## 快速开始

```bash
# 最小命令行容器
./build.sh

# 推荐：XFCE + TigerVNC + PipeWire + 中文字体
./build.sh --xfce

# 同时把镜像放进 App 的 assets，重新构建 APK 后首启自动安装
./build.sh --xfce --with-app-assets
```

产物：

- `dist/arch-rootfs.tar.zst`
- `dist/rootfs.tar.zst`（副本，方便直接导入）

推送到平板：

```bash
adb push dist/arch-rootfs.tar.zst /sdcard/Download/
```

然后在 App 的容器管理页点“导入”，选择该文件。

## 依赖

- Docker（当前用户在 `docker` 组里）
- `zstd`
- x86_64 主机上的 arm64 模拟：首次运行会通过
  `tonistiigi/binfmt` 注册 binfmt；**系统重启后需要重新注册**，
  脚本会自动检测并注册（需要 `--privileged`）。
- 首次构建会下载官方 rootfs（约 791 MB），缓存在 `.cache/`。

## 构建选项

| 参数 / 环境变量 | 说明 |
| --- | --- |
| `--xfce` | 安装 XFCE、TigerVNC、dbus、polkit、PipeWire、WirePlumber 和中文字体 |
| `--fonts` | 只安装中文字体 |
| `--with-app-assets` | 复制到 `app/src/main/assets/rootfs.tar.zst` |
| `--mirror URL` / `MIRROR` | pacman 主镜像，默认清华 TUNA |
| `MIRROR_FALLBACKS` | 备用镜像，默认 USTC + BFSU（大包超时时自动切换） |
| `TZ_NAME` | 时区，默认 `Asia/Shanghai` |
| `ZSTD_LEVEL` | 压缩级别，默认 `3` |
| `ARCH_ROOTFS_URL` | Arch rootfs 地址 |
| `FORCE_BASE_IMPORT=1` | rootfs 更新后强制重新导入 Docker 基础镜像 |
| `KEEP_WORK=1` | 保留 `.work/` 中间文件 |

## 目录结构

```
container/
├── build.sh                  # 主机侧：准备基础镜像 → docker build → 导出 → 组装 tar.zst
├── common/
│   ├── setup-common.sh       # tiny 用户、sudo、polkit、locale、清理
│   └── files/
│       ├── etc/sudoers.d/99-tiny
│       ├── etc/polkit-1/rules.d/99-allow-all.rules
│       └── opt/tiny/export.sh    # App 内“导出容器”时使用
├── arch/
│   ├── Dockerfile            # 基于官方 ArchLinuxARM-aarch64 rootfs
│   ├── setup.sh              # 镜像源、升级、删内核/固件、装软件
│   └── tiny.yaml             # 容器配置模板 → 打包为 /.tiny.yaml
├── dist/                     # 产物（git 忽略）
├── .cache/                   # 下载的 rootfs（git 忽略）
└── .work/                    # 中间目录（git 忽略）
```

## 生成的容器里有什么

- 用户 `tiny` / 密码 `tiny`，uid 1000，免密 sudo；`root` / 密码 `tiny`
- `LANG=en_US.UTF-8`，时区 `Asia/Shanghai`
- DNS：223.5.5.5 / 119.29.29.29 / 8.8.8.8
- pacman 镜像指向清华 TUNA，并配置 USTC/BFSU 作为回退
- 移除了 `linux-aarch64`、`linux-firmware`、内核模块（proot 里用不到）
- 关闭了 pacman 的 Landlock/seccomp 沙箱（在 proot/qemu 下会直接失败）
- 初始化了 pacman keyring
- 缓存、日志、pacman 包缓存已在打包前清理
- `--xfce` 构建时额外带 XFCE、TigerVNC、PipeWire、WirePlumber、中文字体

产物大小参考：最小版约 216 MB，XFCE 版约 797 MB（zstd）。

## 已在 PC 上验证

- chroot 冒烟：`tiny` uid 1000、`sudo -n true` 免密通过、`pacman -Sy` 正常
  （keyring、DNS、pacman 沙箱关闭均生效）
- XFCE：`Xvnc` 正常监听，`xfwm4`、`xfce4-session`、`xfdesktop`、`xfce4-panel`
  全部启动
- AVNC/X11 命令里会预先创建 `/tmp/.X11-unix` 和 `/tmp/.ICE-unix`
  （tiny 不是 root，Xvnc 自己建不了）
- 尚未验证：真机 AVNC 显示、音频/麦克风、打印、外部存储

## 进入桌面

1. 用 `--xfce` 构建并导入容器。
2. 到“功能”页启用 **AVNC 图形界面**（Unix socket，推荐）或 **Termux:X11**。
3. 重新启动容器。

画面太大/太小可以在“功能 → AVNC”里调整缩放，或在选项里启用“高分辨率支持”。

## 在 App 内导出容器

`.tiny.yaml` 带了 `export_command`，容器里安装了 `/opt/tiny/export.sh`。
在 App 里导出时会以 root 进入容器，清理缓存后打包到 `/Public/rootfs.tar.zst`。

> 这条路径还没在真机上完整验证；出问题优先用 `build.sh` 在 PC 上重新构建。

## 已知问题 / TODO

- [ ] **音频/麦克风转发**尚未接好。需要从
      [tiny-computer/images](https://github.com/tiny-computer/images) 取
      `module-tiny-audio.c` / `module-tiny-microphone.c`，在容器里用
      `pkg-config libpipewire-0.3` 编译。Arch 的模块目录是
      `/usr/lib/pipewire-0.3/`，配置放 `/etc/pipewire/pipewire.conf.d/`。
- [ ] 提供预览图 `opt/tiny/preview.png` 并在 `tiny.yaml` 里启用 `preview`。
- [ ] 真机验证 AVNC / X11 桌面、输入法、打印、外部存储。
- [ ] 如果要做“定制 APK”，还需要改 `tc4_app_name`、图标和 `applicationId`
      （`app/build.gradle.kts`），并从上游 Releases 下载 `jniLibs.zip`
      解压到 `app/src/main/jniLibs/arm64-v8a`。

## 与上游同步

```bash
git remote add upstream https://github.com/Cateners/tiny_container.git  # 只需一次
git fetch upstream
git switch arch
git merge upstream/main
```

镜像格式如果有变化，优先参考
[tiny-computer/images](https://github.com/tiny-computer/images) 的
`proot-distro.en.tiny.yaml` 和 `opt/tiny/export.sh`。
