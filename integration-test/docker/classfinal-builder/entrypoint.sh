#!/bin/bash
set -e

echo "=== Building ClassFinal ==="

# 执行 Maven 构建
mvn clean install -DskipTests -f /workspace/pom.xml -B -q -Dorg.slf4j.simpleLogger.log.org.apache.maven.cli.transfer.Slf4jMavenTransferListener=warn

echo "=== ClassFinal Build Complete ==="
ls -lh /workspace/classfinal-fatjar/target/

# 如果传入了参数，执行该命令
if [ $# -gt 0 ]; then
    exec "$@"
fi
