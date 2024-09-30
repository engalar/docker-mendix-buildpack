# Dockerfile to create a Mendix Docker image based on either the source code or
# Mendix Deployment Archive (aka mda file)
FROM --platform=linux/amd64 registry.access.redhat.com/ubi8/ubi-minimal:latest
#This version does a full build originating from the Ubuntu Docker images
LABEL Author="Mendix Digital Ecosystems"
LABEL maintainer="digitalecosystems@mendix.com"

# Set the locale
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV CHROME_VERSION=1109252
ENV NODE_VERSION=16.19.0

# install dependencies & remove package lists
RUN microdnf update -y && \
    microdnf module enable nginx:1.20 -y && \
    microdnf install -y atk at-spi2-atk libdrm libXcomposite libXdamage libXrandr libgbm pango tar unzip glibc-langpack-en python311 openssl nginx nginx-mod-stream java-11-openjdk-headless java-17-openjdk-headless java-21-openjdk-headless tzdata-java fontconfig binutils && \
    microdnf clean all && rm -rf /var/cache/yum

# Set nginx permissions
RUN touch /run/nginx.pid && \
    chown -R 1001:0 /var/log/nginx /var/lib/nginx /run &&\
    chmod -R g=u /var/log/nginx /var/lib/nginx /run

# Set python alias to python3 (required for Datadog)
RUN alternatives --set python /usr/bin/python3

# 下载并安装 Chromium
# https://www.googleapis.com/download/storage/v1/b/chromium-browser-snapshots/o/Linux_x64%2F${CHROME_VERSION}%2Fchrome-linux.zip?generation=1677192533594220&alt=media
RUN curl -s -o chrome-linux.zip "http://172.31.80.1:18081/repository/mendix-cdn/documentgeneration/Linux_x64_1109252_chrome-linux.zip" \
    && unzip chrome-linux.zip -d /opt/ \
    && rm chrome-linux.zip
# 下载并安装 Node.js
# https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz
RUN curl -fsSL "http://172.31.80.1:18081/repository/mendix-cdn/documentgeneration/node-v16.19.0-linux-x64.tar" -o node.tar \
    && tar -xvf node.tar -C /opt/ \
    && mv /opt/node-v${NODE_VERSION}-linux-x64 /opt/node \
    && rm node.tar
# 添加 Node.js 和 Chromium 到 PATH
ENV PATH="/opt/node/bin:/opt/chrome-linux:${PATH}"

# Set the user ID
ARG USER_UID=1001

# Create user (for non-OpenShift clusters)
RUN echo "mendix:x:${USER_UID}:${USER_UID}:mendix user:/opt/mendix/build:/sbin/nologin" >> /etc/passwd
