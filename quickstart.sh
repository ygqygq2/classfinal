#!/bin/bash
#
# ClassFinal 快速体验脚本
# Quick Start Script for ClassFinal
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_DIR="/tmp/classfinal-demo-$$"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

function Print_Step() {
    local message="$1"
    echo -e "${BLUE}==>${NC} $message"
}

function Print_Success() {
    local message="$1"
    echo -e "${GREEN}✓${NC} $message"
}

function Print_Error() {
    local message="$1"
    echo -e "${RED}✗${NC} $message"
}

function Cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
    # 停止后台运行的 Java 进程
    pkill -f "classfinal-test-app" 2>/dev/null || true
}

function Prepare_Test_App() {
    Print_Step "Step 1: 准备测试应用"
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"

    if [ ! -f "$SCRIPT_DIR/integration-test/test-app/target/classfinal-test-app-1.0.0.jar" ]; then
        Print_Step "编译测试应用..."
        (cd "$SCRIPT_DIR/integration-test/test-app" && mvn clean package -q -DskipTests)
    fi

    cp "$SCRIPT_DIR/integration-test/test-app/target/classfinal-test-app-1.0.0.jar" "$TEMP_DIR/app.jar"
    Print_Success "测试应用已准备"
}

function Test_Original_App() {
    Print_Step "Step 2: 测试原始应用（未加密）"
    Print_Step "启动应用（监听 8080 端口）..."
    java -jar app.jar > app.log 2>&1 &
    local app_pid=$!
    sleep 3

    if ! curl -s http://localhost:8080/health > /dev/null; then
        Print_Error "应用启动失败"
        cat app.log
        exit 1
    fi

    Print_Success "应用启动成功"
    curl -s http://localhost:8080/health | jq '.' || curl -s http://localhost:8080/health
    echo ""

    Print_Step "运行测试..."
    local result=$(curl -s http://localhost:8080/test)
    if echo "$result" | grep -q "success.*true"; then
        Print_Success "原始应用测试通过"
    else
        Print_Error "原始应用测试失败"
        echo "$result"
    fi

    kill $app_pid 2>/dev/null || true
    wait $app_pid 2>/dev/null || true
    sleep 1
}

function Encrypt_App() {
    Print_Step "Step 3: 使用 ClassFinal Docker 镜像加密应用"
    Print_Step "拉取镜像: ghcr.io/ygqygq2/classfinal/classfinal:2.0.0"

    if ! docker pull ghcr.io/ygqygq2/classfinal/classfinal:2.0.0 2>&1 | grep -q "Status.*Downloaded\|Status.*up to date"; then
        Print_Error "镜像拉取失败"
        exit 1
    fi

    Print_Step "加密中（密码: demo123）..."
    echo -e "Y\nY" | docker run --rm -i \
        -v "$TEMP_DIR:/data" \
        -w /data \
        --entrypoint java \
        ghcr.io/ygqygq2/classfinal/classfinal:2.0.0 \
        -jar /app/app.jar \
        -file app.jar \
        -pwd demo123 \
        -packages "io.github.ygqygq2.test" || true

    if [ ! -f "app-encrypted.jar" ]; then
        Print_Error "加密失败"
        exit 1
    fi

    Print_Success "加密完成: app-encrypted.jar"
}

function Test_Encrypted_App() {
    Print_Step "Step 4: 测试加密后的应用"
    Print_Step "启动加密应用（需要正确密码）..."
    java -javaagent:app-encrypted.jar="-pwd demo123" -jar app-encrypted.jar > app-encrypted.log 2>&1 &
    local encrypted_pid=$!
    sleep 3

    if ! curl -s http://localhost:8080/health > /dev/null; then
        Print_Error "加密应用启动失败"
        cat app-encrypted.log
        exit 1
    fi

    Print_Success "加密应用启动成功"
    curl -s http://localhost:8080/health | jq '.' || curl -s http://localhost:8080/health
    echo ""

    Print_Step "运行测试..."
    local result=$(curl -s http://localhost:8080/test)
    if echo "$result" | grep -q "success.*true"; then
        Print_Success "加密应用测试通过"
    else
        Print_Error "加密应用测试失败"
        echo "$result"
    fi

    kill $encrypted_pid 2>/dev/null || true
    wait $encrypted_pid 2>/dev/null || true
    sleep 1
}

function Test_Wrong_Password() {
    Print_Step "Step 5: 验证密码保护（使用错误密码）"
    Print_Step "尝试用错误密码启动..."
    timeout 5 java -javaagent:app-encrypted.jar="-pwd wrongpass" -jar app-encrypted.jar > wrong-pwd.log 2>&1 || true

    if grep -q "密码错误\|invalid password\|Startup failed" wrong-pwd.log; then
        Print_Success "密码保护生效 - 错误密码无法启动"
    else
        Print_Error "密码保护可能未生效"
        cat wrong-pwd.log
    fi
}

function Show_Summary() {
    echo ""
    echo "========================================"
    echo -e "${GREEN}✓ 快速体验完成！${NC}"
    echo "========================================"
    echo ""
    echo "体验了以下功能:"
    echo "  1. ✓ 原始应用正常运行"
    echo "  2. ✓ Docker 镜像加密"
    echo "  3. ✓ 加密应用正常运行"
    echo "  4. ✓ 密码保护生效"
    echo ""
    echo "下一步:"
    echo "  - 查看文档: README.md"
    echo "  - Maven 插件使用: docs/03-development-guide.md"
    echo "  - Maven Central: https://search.maven.org/search?q=g:io.github.ygqygq2"
    echo ""
}

function Main() {
    echo ""
    echo "========================================"
    echo "  ClassFinal 快速体验"
    echo "  ClassFinal Quick Demo"
    echo "========================================"
    echo ""

    Prepare_Test_App
    Test_Original_App
    Encrypt_App
    Test_Encrypted_App
    Test_Wrong_Password
    Show_Summary
}

trap Cleanup EXIT

Main "$@"
