#!/bin/bash
set -e

echo "=== Building Test Application ==="

mvn clean package

echo "=== Test App Build Complete ==="
ls -lh /workspace/integration-test/test-app/target/

# 复制 JAR 到集成测试目录
cp /workspace/integration-test/test-app/target/*.jar /workspace/integration-test/

exec "$@"
