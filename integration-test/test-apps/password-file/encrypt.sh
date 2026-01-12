#!/bin/bash
set -euo pipefail

echo "=== 使用密码文件参数加密 ==="

# 使用 --password-file 参数加密
java -jar /opt/classfinal/classfinal-fatjar.jar \
    -file /workspace/test-app.jar \
    -output /workspace/encrypted-app.jar \
    -packages net.roseboy.test \
    --password-file /workspace/secrets/password.txt

# 检查加密结果
if [ -f /workspace/encrypted-app.jar ]; then
    echo "✓ 使用密码文件加密成功"
    ls -lh /workspace/encrypted-app.jar
else
    echo "✗ 加密失败，未找到输出文件"
    exit 1
fi
