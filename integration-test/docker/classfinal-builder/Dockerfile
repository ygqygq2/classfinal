# ClassFinal 构建镜像
FROM maven:3.8-openjdk-8

LABEL maintainer="ygqygq2"
LABEL description="ClassFinal Maven Build Environment"

# 设置工作目录
WORKDIR /workspace

# 复制 entrypoint 脚本
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["build"]
