#!/bin/bash
set -euo pipefail

echo "=== 密码文件参数测试准备 ==="

# 复制测试应用
cp /app/test-app.jar /workspace/test-app.jar

# 复制密码文件
mkdir -p /workspace/secrets
cp /test-password/password.txt /workspace/secrets/

echo "✓ 密码文件测试环境准备完成"
ls -lh /workspace/
cat /workspace/secrets/password.txt | wc -c
