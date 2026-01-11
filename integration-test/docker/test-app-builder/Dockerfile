# 测试应用构建镜像
FROM ghcr.io/ygqygq2/classfinal/base:latest AS base
FROM maven:3.8-openjdk-8

ARG USE_CHINA_MIRROR=true

LABEL org.opencontainers.image.source="https://github.com/ygqygq2/classfinal"
LABEL org.opencontainers.image.description="ClassFinal Test Application Build Environment"
LABEL maintainer="ygqygq2"

# 配置 Maven 使用阿里云镜像（可选）
RUN if [ "$USE_CHINA_MIRROR" = "true" ]; then \
    mkdir -p /root/.m2 && \
    echo '<?xml version="1.0" encoding="UTF-8"?>' > /root/.m2/settings.xml && \
    echo '<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"' >> /root/.m2/settings.xml && \
    echo '  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"' >> /root/.m2/settings.xml && \
    echo '  xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 http://maven.apache.org/xsd/settings-1.0.0.xsd">' >> /root/.m2/settings.xml && \
    echo '  <mirrors>' >> /root/.m2/settings.xml && \
    echo '    <mirror>' >> /root/.m2/settings.xml && \
    echo '      <id>aliyunmaven</id>' >> /root/.m2/settings.xml && \
    echo '      <mirrorOf>central</mirrorOf>' >> /root/.m2/settings.xml && \
    echo '      <name>阿里云公共仓库</name>' >> /root/.m2/settings.xml && \
    echo '      <url>https://maven.aliyun.com/repository/public</url>' >> /root/.m2/settings.xml && \
    echo '    </mirror>' >> /root/.m2/settings.xml && \
    echo '  </mirrors>' >> /root/.m2/settings.xml && \
    echo '</settings>' >> /root/.m2/settings.xml; \
    fi

# 从 base 镜像复制 entrypoint.sh
COPY --from=base /usr/local/bin/entrypoint.sh /usr/local/bin/entrypoint.sh

# 复制所有测试应用源码
COPY integration-test/test-apps /workspace/integration-test/test-apps

# 默认工作目录（可通过 docker-compose 的 working_dir 覆盖）
WORKDIR /workspace/integration-test/test-apps/basic

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["build"]
