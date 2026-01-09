# ClassFinal 加密器镜像
FROM eclipse-temurin:8-jre

LABEL maintainer="ygqygq2"
LABEL description="ClassFinal Encryption Tool Runtime"

WORKDIR /app

COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
