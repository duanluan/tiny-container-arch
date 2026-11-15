# Tiny Container Arch（个人分支）

这是 [Cateners/tiny_container](https://github.com/Cateners/tiny_container) 的
Arch Linux ARM 定制分支。

- App 仓库：<https://github.com/duanluan/tiny-container-arch>
- 容器镜像仓库：<https://github.com/duanluan/tiny-container-arch-images>
- 默认分支：`arch`

## 相对上游的改动

- 空容器页的“下载容器”链接改为镜像仓库：
  `https://github.com/duanluan/tiny-container-arch-images/releases`
- 帮助页、更新提示、更新检查均指向本仓库：
  - `UpdateChecker.kt`
  - `HelpFragment.kt`
  - `ContainerMainFragment.kt`
- App 版本号：`4.2.3-arch2`（`versionCode = 4020302`）
- 构建套件已迁到镜像仓库，App 仓库更接近上游，方便同步

## 构建 APK

```bash
# 1. 上游预编译库
gh release download v4.2.2 -R Cateners/tiny_container -p jniLibs.zip -D /tmp/tc-jni --clobber
mkdir -p app/src/main/jniLibs
unzip -q /tmp/tc-jni/jniLibs.zip -d app/src/main/

# 2. 签名配置（首次）
#    默认路径：~/.config/tiny-container-arch/keystore.properties
#    格式：
#    storeFile=/path/to/release.jks
#    storePassword=...
#    keyAlias=tiny-container-arch
#    keyPassword=...

# 3. 构建 + 签名
./scripts/build-apk.sh
```

产物：`app/build/outputs/apk/release/tiny-container-arch.apk`

> 签名密钥在 `~/.config/tiny-container-arch/release.jks`，请务必备份。
> 丢失后无法覆盖安装后续版本，只能卸载重装（会清空 App 数据）。

## 发布 App

更新检查读取本仓库的 `releases/latest`，tag 使用 `v<版本>-arch<N>`：

```bash
gh release create v4.2.3-arch2 \
  app/build/outputs/apk/release/tiny-container-arch.apk \
  -R duanluan/tiny-container-arch \
  --title "Tiny Container Arch 4.2.3-arch2" \
  --notes "Arch 定制版" \
  --latest
```

## 容器镜像

镜像不在本仓库，去
[tiny-container-arch-images](https://github.com/duanluan/tiny-container-arch-images)
构建和发布。

## 与上游同步

```bash
git remote add upstream https://github.com/Cateners/tiny_container.git  # 只需一次
git fetch upstream
git switch arch
git merge upstream/main
```

冲突通常集中在上面提到的几个 URL 文件和 `values*/strings.xml`。
