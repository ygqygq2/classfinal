# ClassFinal Web UI 多阶段构建
FROM maven:3.9-eclipse-temurin-21 AS builder

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

# 复制父项目 pom 和核心模块（用于本地构建依赖）
COPY pom.xml .
COPY classfinal-core ./classfinal-core
COPY classfinal-fatjar ./classfinal-fatjar
COPY classfinal-maven-plugin ./classfinal-maven-plugin
COPY classfinal-web ./classfinal-web

# 先构建并安装依赖到本地仓库
RUN mvn install -pl classfinal-core -am -DskipTests -Dgpg.skip=true -B -q \
    -Dorg.slf4j.simpleLogger.log.org.apache.maven.cli.transfer.Slf4jMavenTransferListener=warn

# 构建 classfinal-web
WORKDIR /build/classfinal-web
RUN mvn clean package -DskipTests -B -q \
    -Dorg.slf4j.simpleLogger.log.org.apache.maven.cli.transfer.Slf4jMavenTransferListener=warn

# 运行时镜像
FROM eclipse-temurin:21-jre-alpine

LABEL org.opencontainers.image.source="https://github.com/ygqygq2/classfinal"
LABEL org.opencontainers.image.description="ClassFinal Web UI"
LABEL maintainer="ygqygq2"

WORKDIR /app

# 从构建阶段复制 jar
COPY --from=builder /build/classfinal-web/target/classfinal-web-*.jar /app/app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
