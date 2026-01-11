# ClassFinal 多阶段构建
FROM maven:3.8-openjdk-8 AS builder

# 构建参数：是否使用国内镜像源（默认使用）
ARG USE_CHINA_MIRROR=true

WORKDIR /build

# 配置 Maven 国内镜像源
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

COPY pom.xml .
COPY classfinal-core ./classfinal-core
COPY classfinal-fatjar ./classfinal-fatjar
COPY classfinal-maven-plugin ./classfinal-maven-plugin
COPY classfinal-web ./classfinal-web

# 本地构建跳过 GPG 签名
RUN mvn clean install -DskipTests -Dgpg.skip=true -B -q -Dorg.slf4j.simpleLogger.log.org.apache.maven.cli.transfer.Slf4jMavenTransferListener=warn

# 运行时镜像
FROM eclipse-temurin:8-jre-alpine

LABEL org.opencontainers.image.source="https://github.com/ygqygq2/classfinal"
LABEL org.opencontainers.image.description="ClassFinal - Java 类文件加密工具"
LABEL maintainer="ygqygq2"
LABEL version="2.0.0"
LABEL org.opencontainers.image.source="https://github.com/ygqygq2/classfinal"
LABEL org.opencontainers.image.description="ClassFinal - Java Class Encryption Tool"
LABEL org.opencontainers.image.licenses="Apache-2.0"

WORKDIR /app

# 从构建阶段复制 jar 并重命名为统一的 app.jar
COPY --from=builder /build/classfinal-fatjar/target/classfinal-fatjar-*.jar /app/app.jar

# 复制通用启动脚本
COPY integration-test/docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 环境变量配置
ENV PASSWORD="" \
    PACKAGES="" \
    INPUT_FILE="" \
    OUTPUT_FILE="" \
    TARGET_JAR=""

ENTRYPOINT ["/entrypoint.sh"]
CMD ["run"]
