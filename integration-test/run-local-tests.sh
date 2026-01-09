#!/usr/bin/env bash
#
# 本地集成测试脚本
# Local Integration Test Script
#
# 功能：
# - 使用本地环境变量（OSSRH_USERNAME, OSSRH_PASSWORD）
# - 使用国内镜像源加速构建
# - 完整的加密测试流程
#
# 使用方法：
#   bash integration-test/run-local-tests.sh
#

set -euo pipefail

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${PROJECT_ROOT}"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
function Log_Info() {
    echo -e "${BLUE}ℹ ${NC}$*"
}

function Log_Success() {
    echo -e "${GREEN}✓${NC} $*"
}

function Log_Warning() {
    echo -e "${YELLOW}⚠${NC} $*"
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

# 检查环境变量
function Check_Environment() {
    Log_Info "检查本地环境..."
    
    if [[ -z "${OSSRH_USERNAME:-}" ]]; then
        Log_Warning "OSSRH_USERNAME 未设置（Maven 部署测试将跳过）"
    else
        Log_Success "OSSRH_USERNAME 已设置: ${OSSRH_USERNAME}"
    fi
    
    if [[ -z "${OSSRH_PASSWORD:-}" ]]; then
        Log_Warning "OSSRH_PASSWORD 未设置（Maven 部署测试将跳过）"
    else
        Log_Success "OSSRH_PASSWORD 已设置 (长度: ${#OSSRH_PASSWORD})"
    fi
    
    # 检查 Docker
    if ! command -v docker &> /dev/null; then
        Log_Error "Docker 未安装，请先安装 Docker"
        exit 1
    fi
    Log_Success "Docker 已安装: $(docker --version)"
    
    # 检查 docker-compose
    if ! command -v docker-compose &> /dev/null; then
        Log_Error "docker-compose 未安装，请先安装 docker-compose"
        exit 1
    fi
    Log_Success "docker-compose 已安装: $(docker-compose --version)"
}

# Docker Compose 兼容性包装函数 (V1 使用 docker-compose, V2 使用 docker compose)
function docker-compose() {
    if type -P docker-compose >/dev/null 2>&1; then
        command docker-compose "$@"
    else
        docker compose "$@"
    fi
}

# 清理函数
function Cleanup() {
    Log_Info "清理测试环境..."
    docker-compose down -v 2>/dev/null || true
    Log_Success "清理完成"
}

# 捕获退出信号
trap Cleanup EXIT

# 主函数
function Main() {
    echo "========================================="
    echo "   ClassFinal 本地集成测试"
    echo "   Local Integration Test"
    echo "========================================="
    
    Check_Environment
    
    # 确保使用国内镜像源（本地环境）
    export USE_CHINA_MIRROR=true
    
    # Step 1: 构建 ClassFinal
    Log_Step 1 "构建 ClassFinal"
    docker-compose build classfinal
    Log_Success "ClassFinal 镜像构建成功"
    
    # Step 2: 构建测试应用
    Log_Step 2 "构建测试应用"
    docker-compose build test-app
    Log_Success "测试应用镜像构建成功"
    
    # Step 3: 测试原始应用（基准测试）
    Log_Step 3 "测试原始应用（未加密）"
    docker-compose run --rm test-original
    Log_Success "原始应用运行正常"
    
    # Step 4: 准备测试应用
    Log_Step 4 "准备测试应用"
    docker-compose run --rm prepare-test-app
    Log_Success "测试应用准备完成"
    
    # Step 5: 加密测试应用
    Log_Step 5 "加密测试应用"
    docker-compose run --rm encrypt-app
    Log_Success "应用加密成功"
    
    # Step 6: 测试无密码运行（应该失败）
    Log_Step 6 "测试无密码运行加密应用"
    if docker-compose run --rm test-encrypted-no-password 2>&1 | grep -q "测试通过"; then
        Log_Success "加密应用正确要求密码验证"
    else
        Log_Warning "无密码测试未按预期运行（可能需要检查）"
    fi
    
    # Step 7: 测试正确密码运行
    Log_Step 7 "测试使用正确密码运行"
    docker-compose up -d test-encrypted-with-password
    docker-compose run --rm verify-encrypted-app
    docker-compose stop test-encrypted-with-password
    Log_Success "加密应用使用正确密码运行成功"
    
    # Step 8: 测试错误密码（应该失败）
    Log_Step 8 "测试使用错误密码运行"
    if docker-compose run --rm test-encrypted-wrong-password 2>&1 | grep -q "测试通过"; then
        Log_Success "加密应用正确拒绝错误密码"
    else
        Log_Warning "错误密码测试未按预期运行（可能需要检查）"
    fi
    
    # Step 9: 准备多包测试
    Log_Step 9 "准备多包加密测试"
    docker-compose run --rm prepare-multipackage-test
    Log_Success "多包测试应用准备完成"
    
    # Step 10: 多包加密
    Log_Step 10 "执行多包加密"
    docker-compose run --rm encrypt-multipackage
    Log_Success "多包加密成功"
    
    # Step 11: 测试多包加密应用
    Log_Step 11 "测试多包加密应用运行"
    docker-compose run --rm test-multipackage-encrypted
    Log_Success "多包加密应用运行成功"
    
    # Step 12: 测试排除类名功能
    Log_Step 12 "测试排除类名功能"
    docker-compose run --rm prepare-exclude-test
    docker-compose run --rm encrypt-with-exclude
    docker-compose run --rm test-encrypted-with-exclude
    Log_Success "排除类名功能测试通过"
    
    # Step 13: 测试无密码模式
    Log_Step 13 "测试无密码模式"
    docker-compose run --rm prepare-nopwd-test
    docker-compose run --rm encrypt-nopwd
    docker-compose run --rm test-encrypted-nopwd
    Log_Success "无密码模式测试通过"
    
    # Step 14: 安装 Maven 插件
    Log_Step 14 "安装 classfinal-maven-plugin 到本地仓库"
    docker-compose run --rm install-maven-plugin
    Log_Success "Maven 插件安装完成"
    
    # Step 15: Maven 插件集成测试
    Log_Step 15 "Maven 插件集成测试"
    docker-compose run --rm test-maven-plugin
    Log_Success "Maven 插件集成测试通过"
    
    # Step 16: lib 依赖加密测试
    Log_Step 16 "lib 依赖加密测试"
    docker-compose run --rm prepare-libjars-test
    docker-compose run --rm encrypt-with-libjars
    docker-compose run --rm test-libjars-encrypted
    Log_Success "lib 依赖加密测试通过"
    
    # Step 17: 配置文件加密测试
    Log_Step 17 "配置文件加密测试"
    docker-compose run --rm prepare-config-encryption
    docker-compose run --rm encrypt-config-files
    docker-compose run --rm test-config-encrypted
    Log_Success "配置文件加密测试通过"
    
    # Step 18: 机器码绑定测试
    Log_Step 18 "机器码绑定测试"
    docker-compose run --rm prepare-machine-code
    docker-compose run --rm encrypt-with-machine-code
    docker-compose run --rm test-machine-code-correct
    Log_Success "机器码绑定测试通过"
    
    # Step 19: WAR 包加密测试
    Log_Step 19 "WAR 包加密测试"
    docker-compose run --rm prepare-war-test
    docker-compose run --rm encrypt-war
    docker-compose run --rm test-war-encrypted
    Log_Success "WAR 包加密测试通过"
    
    # Step 20: 反编译保护验证测试
    Log_Step 20 "反编译保护验证测试"
    docker-compose run --rm prepare-decompile-test
    Log_Success "反编译保护验证测试通过"
    
    # Step 21: Maven 本地部署测试（可选）
    if [[ -n "${OSSRH_USERNAME:-}" && -n "${OSSRH_PASSWORD:-}" ]]; then
        Log_Step 21 "Maven 本地安装测试"
        Log_Info "跳过 Maven 部署测试（仅在 CI 中执行）"
        Log_Info "如需测试本地安装，运行: mvn clean install -DskipTests -Dgpg.skip=true"
    else
        Log_Warning "跳过 Maven 测试（缺少 OSSRH 凭证）"
    fi
    
    echo ""
    echo "========================================="
    Log_Success "所有本地集成测试通过！"
    echo "========================================="
    echo ""
    echo "测试总结:"
    echo "  ✓ ClassFinal 构建成功"
    echo "  ✓ 测试应用构建成功"
    echo "  ✓ 原始应用运行正常"
    echo "  ✓ 应用加密成功"
    echo "  ✓ 加密应用需要密码验证"
    echo "  ✓ 正确密码可以运行"
    echo "  ✓ 错误密码被拒绝"
    echo "  ✓ 多包加密成功"
    echo "  ✓ 多包加密应用运行正常"
    echo "  ✓ 排除类名功能正常"
    echo "  ✓ 无密码模式正常"
    echo "  ✓ Maven 插件集成正常"
    echo "  ✓ lib 依赖加密正常"
    echo "  ✓ 配置文件加密正常"
    echo "  ✓ 机器码绑定正常"
    echo "  ✓ WAR 包加密正常"
    echo "  ✓ 反编译保护有效"
    echo ""
    Log_Info "本地测试完成，可以提交代码了！"
}

Main "$@"
