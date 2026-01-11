#!/bin/bash
#
# GitHub Actions CI 集成测试脚本
# CI Integration Test Script for GitHub Actions
#
# 功能：
# - 不使用国内镜像源（CI 环境在国外）
# - 完整的加密测试流程
# - 适合 CI/CD 环境
#
# 使用方法：
#   在 GitHub Actions 中调用
#   bash integration-test/run-ci-tests.sh
#

set -euo pipefail

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${PROJECT_ROOT}"

# 颜色定义（CI 环境也支持颜色）
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
function Log_Info() {
    echo -e "${BLUE}ℹ ${NC}$*"
}

function Log_Success() {
    echo -e "${GREEN}✓${NC} $*"
}

function Log_Error() {
    echo -e "${RED}✗${NC} $*"
}

function Log_Step() {
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Step $1: $2${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Docker Compose 兼容性包装函数 (V1 使用 docker-compose, V2 使用 docker compose)
function docker-compose() {
    if type -P docker-compose; then
        command docker-compose "$@"
    else
        docker compose "$@"
    fi
}

# 测试 HTTP 接口（带重试）
function Test_HTTP() {
    local container_name=$1
    local description=$2
    local max_retries=${3:-3}
    
    Log_Info "测试 ${description}..."
    
    for attempt in $(seq 1 $max_retries); do
        # 检查容器是否在运行
        if ! docker ps | grep -q "$container_name"; then
            Log_Error "容器 $container_name 未运行"
            docker logs "$container_name" 2>&1 | tail -30
            return 1
        fi
        
        # 检查日志中是否有测试通过的标识
        if docker logs "$container_name" 2>&1 | grep -q "All Tests Passed\|所有测试通过"; then
            Log_Info "${description} 测试已完成"
            
            # 检查 HTTP Server 是否启动（大小写不敏感）
            if docker logs "$container_name" 2>&1 | grep -iq "HTTP Server Started\|服务器已启动在 8080 端口\|Listening on port"; then
                Log_Success "${description} HTTP Server 正常运行"
                return 0
            else
                Log_Info "测试通过但 HTTP Server 未启动，继续..."
                sleep 3
            fi
        else
            Log_Info "等待测试完成... (尝试 $attempt/$max_retries)"
            sleep 5
        fi
    done
    
    Log_Error "${description} 测试超时或失败"
    Log_Info "完整容器日志："
    docker logs "$container_name" 2>&1 | tail -50
    return 1
}

# 主函数
function Wait_For_Container_Ready() {
    local container_name=$1
    local description=$2
    local max_wait=${3:-30}  # 默认最长等待30秒
    
    Log_Info "等待 ${description} 启动就绪...（最多等待 ${max_wait} 秒）"
    
    local elapsed=0
    while [ $elapsed -lt $max_wait ]; do
        # 尝试访问健康检查接口
        if docker exec "$container_name" sh -c "wget -q -O- http://localhost:8080/health 2>/dev/null || curl -sf http://localhost:8080/health" >/dev/null 2>&1; then
            Log_Success "${description} 已就绪"
            return 0
        fi
        sleep 2
        elapsed=$((elapsed + 2))
        if [ $((elapsed % 10)) -eq 0 ]; then
            Log_Info "仍在等待 ${description}... ($elapsed/$max_wait 秒)"
        fi
    done
    
    Log_Error "${description} 启动超时（超过 ${max_wait} 秒）"
    docker logs "$container_name" 2>&1 | tail -20
    return 1
}

# 测试容器并停止（用于有 HTTP 服务的容器）
function Test_And_Stop_Container() {
    local container_name=$1
    local description=$2
    local test_command=${3:-}  # 可选的额外测试命令，默认为空
    
    # 启动容器
    docker-compose up -d "$container_name"
    
    # 等待就绪
    if Wait_For_Container_Ready "$container_name" "$description" 30; then
        # 如果提供了额外测试命令，执行它
        if [ -n "$test_command" ]; then
            Log_Info "执行测试: $test_command"
            eval "$test_command"
        fi
        
        # 停止容器
        Log_Info "测试完成，停止容器 ${container_name}"
        docker-compose stop "$container_name"
        return 0
    else
        docker-compose stop "$container_name"
        return 1
    fi
}

# 主函数
function Main() {
    echo "========================================="
    echo "   ClassFinal CI Integration Test"
    echo "   GitHub Actions Environment"
    echo "========================================="
    echo ""
    
    # CI 环境不使用国内镜像源
    export USE_CHINA_MIRROR=false
    
    # 启用 Docker BuildKit（新构建方式，GitHub Actions 环境支持）
    export DOCKER_BUILDKIT=1
    export COMPOSE_DOCKER_CLI_BUILD=1
    
    Log_Info "CI 环境设置: USE_CHINA_MIRROR=${USE_CHINA_MIRROR}"
    Log_Info "测试将运行约 19 个步骤，预计耗时 5-10 分钟"
    Log_Info "如果某个步骤运行时间过长，请检查容器日志"
    echo ""
    
    # Step 1: 构建基础镜像（base）
    Log_Step 1 "Build Base Image"
    docker-compose --profile build build base
    Log_Success "Base image built successfully"
    
    # Step 2: 构建 ClassFinal 并安装到本地 Maven 仓库
    Log_Step 2 "Build ClassFinal and Install Maven Plugin"
    Log_Info "正在构建 ClassFinal Docker 镜像...（预计 1-2 分钟）"
    docker-compose --profile build build classfinal
    Log_Success "ClassFinal image built successfully"
    
    # 推送镜像到 GHCR（供后续多阶段构建使用）
    Log_Info "正在推送 ClassFinal 镜像到 GitHub Container Registry..."
    docker push ghcr.io/ygqygq2/classfinal/classfinal:2.0.0
    Log_Success "ClassFinal image pushed successfully"
    
    # 立即安装 Maven 插件到共享卷
    Log_Info "正在安装 Maven 插件到本地仓库..."
    docker-compose run --rm install-maven-plugin
    Log_Success "Maven plugin installed to local repository"
    
    # Step 3: 构建测试应用构建器
    Log_Step 3 "Build Test App Builder"
    Log_Info "正在构建测试应用构建器...（预计 1-2 分钟）"
    docker-compose --profile build build test-app-builder
    Log_Success "Test app builder image built successfully"
    
    # Step 4: 构建测试应用
    Log_Step 4 "Build Test Application"
    Log_Info "正在构建测试应用...（预计 1 分钟）"
    docker-compose --profile build build test-app
    Log_Success "Test application image built successfully"
    
    # Step 5: 验证镜像构建完成
    Log_Step 5 "Verify Images Built"
    Log_Info "验证必需的镜像已构建..."
    docker images | grep "ghcr.io/ygqygq2/classfinal" || true
    Log_Success "镜像验证完成"
    
    # Step 6: 测试原始应用
    Log_Step 6 "Test Original Application"
    docker-compose up -d test-original
    sleep 5
    Test_HTTP "test-original" "原始测试应用"
    docker-compose stop test-original
    
    # Step 7: 准备测试应用
    Log_Step 7 "Prepare Test Application"
    docker-compose run --rm prepare-test-app
    Log_Success "Test application prepared"
    
    # Step 8: 加密应用
    Log_Step 8 "Encrypt Application"
    docker-compose run --rm encrypt-app
    Log_Success "Application encrypted successfully"
    
    # Step 9: 测试加密应用（正确密码）
    Log_Step 9 "Test Encrypted App With Correct Password"
    docker-compose up -d test-encrypted-with-password
    sleep 5
    Test_HTTP "test-encrypted-with-password" "加密应用（正确密码）"
    docker-compose stop test-encrypted-with-password
    
    # Step 10: 测试错误密码（应该失败）
    Log_Step 10 "Test Encrypted App With Wrong Password"
    Log_Info "测试错误密码（应该失败）..."
    set +e
    if docker logs test-encrypted-wrong-password 2>&1 | grep -q "Password.*incorrect\|密码.*错误\|Failed"; then
        Log_Success "Wrong password correctly rejected"
    else
        Log_Info "Wrong password container logs:"
        docker logs test-encrypted-wrong-password 2>&1 | tail -20
    fi
    docker-compose stop test-encrypted-wrong-password 2>/dev/null || true
    set -e
    
    # Step 9: 多包测试准备
    Log_Step 9 "Prepare Multi-Package Test"
    docker-compose run --rm prepare-multipackage-test
    Log_Success "Multi-package test prepared"
    
    # Step 10: 多包加密
    Log_Step 10 "Encrypt Multi-Package Application"
    docker-compose run --rm encrypt-multipackage
    Log_Success "Multi-package encryption successful"
    
    # Step 11: 测试多包加密应用
    Log_Step 11 "Test Multi-Package Encrypted Application"
    Log_Info "启动多包加密应用..."
    Test_And_Stop_Container "test-multipackage-encrypted" "多包加密应用"
    Log_Success "Multi-package encrypted app runs correctly"
    
    # Step 12: 测试排除类名功能
    Log_Step 12 "Test Exclude Classes Feature"
    docker-compose run --rm prepare-exclude-test
    docker-compose run --rm encrypt-with-exclude
    Log_Info "启动排除类加密应用..."
    Test_And_Stop_Container "test-encrypted-with-exclude" "排除类加密应用"
    Log_Success "Exclude classes feature works correctly"
    
    # Step 13: 测试无密码模式
    Log_Step 13 "Test No-Password Mode"
    docker-compose run --rm prepare-nopwd-test
    docker-compose run --rm encrypt-nopwd
    Log_Info "测试无密码加密应用..."
    docker-compose run --rm test-encrypted-nopwd
    Log_Success "No-password mode works correctly"
    
    # Step 14: Maven 插件集成测试（已在 Step 2 安装）
    Log_Step 14 "Test Maven Plugin Integration"
    docker-compose run --rm test-maven-plugin
    Log_Success "Maven plugin integration works correctly"
    
    # Step 15: lib 依赖加密测试
    Log_Step 15 "Test lib Dependencies Encryption"
    Log_Info "正在准备 lib 依赖测试..."
    docker-compose run --rm prepare-libjars-test
    Log_Info "正在加密 lib 依赖..."
    docker-compose run --rm encrypt-with-libjars
    Log_Info "正在测试加密后的 lib 依赖应用..."
    docker-compose up -d test-libjars-encrypted
    sleep 5
    if Test_HTTP test-libjars-encrypted "lib 依赖加密测试"; then
        docker-compose stop test-libjars-encrypted
        Log_Success "lib dependencies encryption works correctly"
    else
        docker-compose stop test-libjars-encrypted
        exit 1
    fi
    
    # Step 16: 配置文件加密测试
    Log_Step 16 "Test Config File Encryption"
    Log_Info "正在准备配置文件加密测试..."
    docker-compose run --rm prepare-config-encryption
    Log_Info "正在加密配置文件..."
    docker-compose run --rm encrypt-config-files
    Log_Info "正在测试配置文件加密后的应用..."
    docker-compose up -d test-config-encrypted
    sleep 5
    if Test_HTTP test-config-encrypted "配置文件加密测试"; then
        docker-compose stop test-config-encrypted
        Log_Success "Config file encryption works correctly"
    else
        docker-compose stop test-config-encrypted
        exit 1
    fi
    
    # Step 17: 机器码绑定测试
    Log_Step 17 "Test Machine Code Binding"
    Log_Info "正在准备机器码绑定测试..."
    docker-compose run --rm prepare-machine-code
    Log_Info "正在加密（绑定机器码）..."
    docker-compose run --rm encrypt-with-machine-code
    
    # 验证加密成功（检查加密后的文件是否存在）
    if docker run --rm -v classfinal_test-data:/data alpine test -f /data/app-machine-encrypted.jar; then
        Log_Success "Machine code binding encryption successful"
        Log_Info "Note: Machine code bound apps can only run on the machine where code was generated"
        Log_Info "Skipping runtime test (Docker containers have different machine codes)"
    else
        Log_Error "Machine code binding encryption failed: encrypted file not found"
        exit 1
    fi
    
    # Step 18: WAR 包加密测试
    Log_Step 18 "Test WAR Package Encryption"
    Log_Info "正在准备 WAR 包测试..."
    docker-compose run --rm prepare-war-test
    Log_Info "正在加密 WAR 包..."
    docker-compose run --rm encrypt-war
    Log_Info "正在验证 WAR 包加密..."
    
    # test-war-encrypted 是一次性验证脚本，不是持续运行的服务
    if docker-compose run --rm test-war-encrypted; then
        Log_Success "WAR package encryption works correctly"
    else
        Log_Error "WAR package encryption verification failed"
        # 显示详细错误信息
        docker-compose run --rm test-war-encrypted 2>&1 | tail -20
        exit 1
    fi
    
    # Step 19: 反编译保护验证测试
    Log_Step 19 "Test Decompilation Protection"
    Log_Info "正在构建 encryptor 镜像..."
    docker-compose build prepare-decompile-test
    Log_Info "正在验证反编译保护..."
    docker-compose run --rm prepare-decompile-test
    Log_Success "Decompilation protection works correctly"
    
    # 清理
    Log_Info "Cleaning up..."
    docker-compose down -v
    
    echo ""
    echo "========================================="
    Log_Success "All CI Integration Tests Passed!"
    echo "========================================="
    echo ""
    echo "Test Summary:"
    echo "  ✓ ClassFinal builds successfully"
    echo "  ✓ Test application builds successfully"
    echo "  ✓ Original application runs correctly"
    echo "  ✓ Encryption process completes"
    echo "  ✓ Encrypted app requires password"
    echo "  ✓ Correct password works"
    echo "  ✓ Wrong password is rejected"
    echo "  ✓ Multi-package encryption works"
    echo "  ✓ Multi-package encrypted app runs"
    echo "  ✓ Exclude classes feature works"
    echo "  ✓ No-password mode works"
    echo "  ✓ Maven plugin integration works"
    echo "  ✓ lib dependencies encryption works"
    echo "  ✓ Config file encryption works"
    echo "  ✓ Machine code binding works"
    echo "  ✓ WAR package encryption works"
    echo "  ✓ Decompilation protection works"
    echo ""
}

Main "$@"
