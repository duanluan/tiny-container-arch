# Manjaro ARM 容器构建文件（可选 target）
#
# 基础镜像使用 manjarolinux/base 的 arm64 变体。
# 注意：Manjaro ARM 仓库已停更，日常使用建议用 arch/ 下的 Arch Linux ARM。
ARG BASE_IMAGE=manjarolinux/base:latest
FROM ${BASE_IMAGE}

ARG MIRROR=https://mirrors.tuna.tsinghua.edu.cn/manjaro/arm-stable
ARG TZ_NAME=Asia/Shanghai
ARG INSTALL_FONTS=0
ARG INSTALL_XFCE=0

ENV MIRROR=${MIRROR} \
    TZ_NAME=${TZ_NAME} \
    INSTALL_FONTS=${INSTALL_FONTS} \
    INSTALL_XFCE=${INSTALL_XFCE}

COPY common/ /tmp/common/
COPY manjaro/setup.sh /tmp/setup.sh

RUN sh /tmp/setup.sh

CMD ["/bin/bash"]
