#!/bin/bash
set -euo pipefail

echo "=== 使用配置文件参数加密 ==="

# 使用 --config 参数加密
java -jar /opt/classfinal/classfinal-fatjar.jar \
    --config /workspace/config/classfinal-config.yml

# 检查加密结果
if [ -f /workspace/encrypted-app.jar ]; then
    echo "✓ 使用配置文件加密成功"
    ls -lh /workspace/encrypted-app.jar
else
    echo "✗ 加密失败，未找到输出文件"
    exit 1
fi
