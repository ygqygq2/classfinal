#!/bin/bash
set -e

# 这个脚本在当前工作目录执行 Maven 构建
# 工作目录由 docker-compose 的 working_dir 指定

if [ "$1" = "build" ]; then
  echo "=== Building Application in $(pwd) ==="
  mvn clean package -B -q -Dorg.slf4j.simpleLogger.log.org.apache.maven.cli.transfer.Slf4jMavenTransferListener=warn
  echo "=== Build Complete ==="
  if [ -d target ]; then
    ls -lh target/*.jar 2>/dev/null || echo "No JAR files found"
  fi
  shift
fi

exec "$@"
