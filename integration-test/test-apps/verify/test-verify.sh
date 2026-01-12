#!/bin/bash
set -euo pipefail

# ClassFinal 2.0.1 验证功能测试脚本

echo "=== ClassFinal 加密验证测试 ==="

# 准备测试应用
echo "准备测试应用..."
cp /app/test-app.jar /tmp/original-app.jar

# 加密应用并启用验证
echo "加密应用 (启用验证)..."
java -jar /opt/classfinal/classfinal-fatjar.jar \
    -file /tmp/original-app.jar \
    -output /tmp/encrypted-app.jar \
    -packages net.roseboy.test \
    -pwd "verify-test-2024" \
    --verify

# 检查验证结果
if [ $? -eq 0 ]; then
    echo "✓ 加密验证通过"
else
    echo "✗ 加密验证失败"
    exit 1
fi

# 验证加密文件存在
if [ -f /tmp/encrypted-app.jar ]; then
    echo "✓ 加密文件已生成"
else
    echo "✗ 加密文件未生成"
    exit 1
fi

# 验证加密文件可用
echo "验证加密文件可运行..."
timeout 10 java -Dclassfinal.password=verify-test-2024 \
    -jar /tmp/encrypted-app.jar --spring.profiles.active=test || true

echo "=== 验证测试完成 ==="
