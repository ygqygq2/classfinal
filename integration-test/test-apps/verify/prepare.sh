#!/bin/bash
set -euo pipefail

echo "=== 验证测试准备 ==="

# 复制测试应用
cp /app/test-app.jar /workspace/test-app.jar

echo "✓ 验证测试环境准备完成"
ls -lh /workspace/
