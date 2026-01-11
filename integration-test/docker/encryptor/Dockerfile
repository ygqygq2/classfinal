# ClassFinal 加密器镜像
FROM ghcr.io/ygqygq2/classfinal/classfinal:2.0.0 AS classfinal
FROM eclipse-temurin:8-jre

LABEL maintainer="ygqygq2"
LABEL description="ClassFinal Encryption Tool Runtime"

WORKDIR /app

# 从 classfinal 镜像复制 jar 文件
COPY --from=classfinal /app/app.jar /app/app.jar

# 此镜像用于反编译测试等任务，使用 docker-compose 中的 command 定义具体操作
