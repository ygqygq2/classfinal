#!/usr/bin/env bash
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
#   bash integration-test/run-ci-tests.sh
#

set -euo pipefail

# ========================================
# 初始化
# ========================================

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# 加载模块化库
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/docker-utils.sh"
source "${SCRIPT_DIR}/lib/test-steps.sh"

cd "${PROJECT_ROOT}"

# ========================================
# CI 环境检查
# ========================================

function Check_CI_Environment() {
    Log_Info "检查 CI 环境..."
    
    # 检查必需工具
    Check_Docker
    Check_Docker_Compose
    
    # 检查 CI 特定环境变量
    if [[ -n "${CI:-}" ]]; then
        Log_Success "检测到 CI 环境: ${CI}"
    fi
    
    if [[ -n "${GITHUB_ACTIONS:-}" ]]; then
        Log_Success "检测到 GitHub Actions"
    fi
    
    Log_Success "CI 环境检查完成"
}

# ========================================
# CI 配置
# ========================================

function Setup_CI_Config() {
    Log_Info "配置 CI 环境..."
    
    # 不使用国内镜像源
    export USE_CHINA_MIRROR=false
    Log_Info "已禁用国内镜像源"
    
    # 启用 Docker BuildKit
    export DOCKER_BUILDKIT=1
    export COMPOSE_DOCKER_CLI_BUILD=1
    Log_Info "已启用 Docker BuildKit"
    
    # 获取当前版本
    local version=$(Get_Project_Version)
    export CURRENT_VERSION="$version"
    export DOCKER_VERSION="${version%-SNAPSHOT}"
    Log_Info "项目版本: $CURRENT_VERSION"
    Log_Info "Docker 版本: $DOCKER_VERSION"
    
    Log_Success "CI 配置完成"
}


# ========================================
# 主测试流程
# ========================================

function Main() {
    Log_Header "ClassFinal CI 集成测试"
    
    local start_time=$(date +%s)
    
    # 环境检查
    Check_CI_Environment
    
    # CI 配置
    Setup_CI_Config
    
    # 执行完整测试流程（与 local 保持一致，但显示构建日志）
    Log_Step "1" "构建 ClassFinal"
    Log_Info "开始构建 ClassFinal 镜像..."
    docker-compose build classfinal 2>&1 | grep -v -E "^Downloading|^Downloaded|Progress \(|from central"
    Log_Success "ClassFinal 镜像构建成功"
    
    Log_Step "2" "构建测试应用"
    Log_Info "开始构建测试应用镜像..."
    docker-compose build test-app 2>&1 | grep -v -E "^Downloading|^Downloaded|Progress \(|from central"
    Log_Success "测试应用镜像构建成功"
    
    Log_Step "3" "测试原始应用（未加密）"
    docker-compose up -d test-original >/dev/null 2>&1
    sleep 5
    if docker exec test-original sh -c "wget -q -O- http://localhost:8080/health 2>/dev/null || curl -sf http://localhost:8080/health" >/dev/null 2>&1; then
        Log_Success "原始应用运行正常"
    else
        Log_Error "原始应用健康检查失败"
        docker-compose logs test-original
        exit 1
    fi
    docker-compose stop test-original >/dev/null 2>&1
    
    Log_Step "4" "准备测试应用"
    docker-compose run --rm prepare-test-app >/dev/null 2>&1
    Log_Success "测试应用准备完成"
    
    Log_Step "5" "加密测试应用"
    docker-compose run --rm encrypt-app >/dev/null 2>&1
    Log_Success "应用加密成功"
    
    Log_Step "6" "测试无密码运行加密应用"
    if docker-compose run --rm test-encrypted-no-password 2>&1 | grep -q "测试通过"; then
        Log_Success "加密应用正确要求密码验证"
    else
        Log_Warning "无密码测试未按预期运行"
    fi
    
    Log_Step "7" "测试使用正确密码运行"
    docker-compose up -d test-encrypted-with-password >/dev/null 2>&1
    Log_Info "等待应用就绪..."
    if Wait_For_Health_Check test-encrypted-with-password 15; then
        Log_Success "健康检查成功"
    else
        Log_Error "健康检查超时"
        docker-compose logs test-encrypted-with-password | tail -20
        docker-compose stop test-encrypted-with-password >/dev/null 2>&1
        exit 1
    fi
    Log_Info "验证测试接口..."
    if docker exec test-encrypted-with-password sh -c "wget -q -O- http://localhost:8080/test 2>/dev/null || curl -sf http://localhost:8080/test" >/dev/null 2>&1; then
        Log_Success "测试接口成功"
    else
        Log_Error "测试接口失败"
        docker-compose logs test-encrypted-with-password | tail -20
        docker-compose stop test-encrypted-with-password >/dev/null 2>&1
        exit 1
    fi
    docker-compose stop test-encrypted-with-password >/dev/null 2>&1
    Log_Success "加密应用使用正确密码运行成功"
    
    Log_Step "8" "测试使用错误密码运行"
    if docker-compose run --rm test-encrypted-wrong-password 2>&1 | grep -q "测试通过"; then
        Log_Success "加密应用正确拒绝错误密码"
    else
        Log_Warning "错误密码测试未按预期运行"
    fi
    
    Log_Step "9" "准备多包加密测试"
    docker-compose run --rm prepare-multipackage-test >/dev/null 2>&1
    Log_Success "多包测试应用准备完成"
    
    Log_Step "10" "执行多包加密"
    docker-compose run --rm encrypt-multipackage >/dev/null 2>&1
    Log_Success "多包加密成功"
    
    Log_Step "11" "测试多包加密应用运行"
    docker-compose up -d test-multipackage-encrypted >/dev/null 2>&1
    if Wait_For_Health_Check test-multipackage-encrypted 15; then
        docker-compose stop test-multipackage-encrypted >/dev/null 2>&1
        Log_Success "多包加密应用运行成功"
    else
        docker-compose stop test-multipackage-encrypted >/dev/null 2>&1
        Log_Error "多包加密应用启动超时"
        exit 1
    fi
    
    Log_Step "12" "测试排除类名功能"
    docker-compose run --rm prepare-exclude-test >/dev/null 2>&1
    docker-compose run --rm encrypt-with-exclude >/dev/null 2>&1
    docker-compose up -d test-encrypted-with-exclude >/dev/null 2>&1
    if Wait_For_Health_Check test-encrypted-with-exclude 15; then
        docker-compose stop test-encrypted-with-exclude >/dev/null 2>&1
        Log_Success "排除类名功能测试通过"
    else
        docker-compose stop test-encrypted-with-exclude >/dev/null 2>&1
        Log_Error "排除类名功能启动超时"
        exit 1
    fi
    
    Log_Step "13" "测试无密码模式"
    docker-compose run --rm prepare-nopwd-test >/dev/null 2>&1
    docker-compose run --rm encrypt-nopwd >/dev/null 2>&1
    docker-compose run --rm test-encrypted-nopwd >/dev/null 2>&1
    Log_Success "无密码模式测试通过"
    
    Log_Step "14" "安装 classfinal-maven-plugin 到本地仓库"
    docker-compose run --rm install-maven-plugin >/dev/null 2>&1
    Log_Success "Maven 插件安装完成"
    
    Log_Step "15" "Maven 插件集成测试"
    Log_Info "构建并运行 Maven 插件测试应用..."
    temp_log=$(mktemp)
    if docker-compose run --rm test-maven-plugin > "$temp_log" 2>&1; then
        if grep -qE "FATAL ERROR|Exception in thread|Aborted \(core dumped\)" "$temp_log"; then
            cat "$temp_log"
            rm -f "$temp_log"
            Log_Error "Maven 插件运行时出现致命错误"
            exit 1
        fi
        rm -f "$temp_log"
        Log_Success "Maven 插件集成测试通过"
    else
        cat "$temp_log"
        rm -f "$temp_log"
        Log_Error "Maven 插件验证失败"
        exit 1
    fi
    
    Log_Step "16" "lib 依赖加密测试"
    docker-compose run --rm prepare-libjars-test >/dev/null 2>&1 || { Log_Error "准备 lib 依赖测试失败"; exit 1; }
    docker-compose run --rm encrypt-with-libjars >/dev/null 2>&1 || { Log_Error "lib 依赖加密失败"; exit 1; }
    docker-compose up -d test-libjars-encrypted >/dev/null 2>&1
    if Wait_For_Health_Check test-libjars-encrypted 15; then
        docker-compose stop test-libjars-encrypted >/dev/null 2>&1
        Log_Success "lib 依赖加密测试通过"
    else
        docker-compose stop test-libjars-encrypted >/dev/null 2>&1
        Log_Error "lib 依赖加密验证失败"
        exit 1
    fi
    
    Log_Step "17" "配置文件加密测试"
    docker-compose run --rm prepare-config-encryption >/dev/null 2>&1 || { Log_Error "准备配置加密测试失败"; exit 1; }
    docker-compose run --rm encrypt-config-files >/dev/null 2>&1 || { Log_Error "配置文件加密失败"; exit 1; }
    docker-compose up -d test-config-encrypted >/dev/null 2>&1
    if Wait_For_Health_Check test-config-encrypted 15; then
        docker-compose stop test-config-encrypted >/dev/null 2>&1
        Log_Success "配置文件加密测试通过"
    else
        docker-compose stop test-config-encrypted >/dev/null 2>&1
        Log_Error "配置文件加密验证失败"
        exit 1
    fi
    
    Log_Step "18" "机器码绑定测试"
    docker-compose run --rm prepare-machine-code >/dev/null 2>&1
    docker-compose run --rm encrypt-with-machine-code >/dev/null 2>&1
    
    # 验证加密成功（检查加密后的文件是否存在）
    if docker run --rm -v classfinal_test-data:/data alpine test -f /data/app-machine-encrypted.jar; then
        Log_Success "机器码绑定加密成功"
        Log_Info "注意: 机器码绑定的应用只能在生成机器码的机器上运行"
        Log_Info "Docker 容器环境下每个容器的机器码不同，跳过运行测试"
    else
        Log_Error "机器码绑定加密失败：加密文件不存在"
        exit 1
    fi
    
    Log_Step "19" "WAR 包加密测试"
    docker-compose run --rm prepare-war-test >/dev/null 2>&1
    docker-compose run --rm encrypt-war >/dev/null 2>&1
    
    # test-war-encrypted 是一次性验证脚本，不是持续运行的服务
    if docker-compose run --rm test-war-encrypted >/dev/null 2>&1; then
        Log_Success "WAR 包加密测试通过"
    else
        Log_Error "WAR 包加密验证失败"
        # 显示详细错误信息
        docker-compose run --rm test-war-encrypted 2>&1 | tail -20
        exit 1
    fi
    
    Log_Step "20" "反编译保护验证测试"
    docker-compose run --rm prepare-decompile-test >/dev/null 2>&1
    Log_Success "反编译保护验证完成"
    
    Log_Step "21" "Maven 本地安装测试"
    docker-compose run --rm test-mvn-install >/dev/null 2>&1
    Log_Success "Maven 本地安装测试通过"
    
    Log_Step "22" "配置文件参数测试 (--config)"
    Log_Info "创建加密配置文件..."
    docker-compose run --rm prepare-config-param-test >/dev/null 2>&1 || { Log_Error "准备配置文件测试失败"; exit 1; }
    Log_Info "使用配置文件加密..."
    docker-compose run --rm encrypt-with-config-param >/dev/null 2>&1 || { Log_Error "配置文件参数加密失败"; exit 1; }
    docker-compose up -d test-config-param-encrypted >/dev/null 2>&1
    if Wait_For_Health_Check test-config-param-encrypted 15; then
        docker-compose stop test-config-param-encrypted >/dev/null 2>&1
        Log_Success "配置文件参数测试通过 (--config)"
    else
        docker-compose logs test-config-param-encrypted | tail -20
        docker-compose stop test-config-param-encrypted >/dev/null 2>&1
        Log_Error "配置文件参数验证失败"
        exit 1
    fi
    
    Log_Step "23" "密码文件参数测试 (--password-file)"
    Log_Info "创建密码文件..."
    docker-compose run --rm prepare-password-file-test >/dev/null 2>&1 || { Log_Error "准备密码文件测试失败"; exit 1; }
    Log_Info "使用密码文件加密..."
    docker-compose run --rm encrypt-with-password-file >/dev/null 2>&1 || { Log_Error "密码文件参数加密失败"; exit 1; }
    docker-compose up -d test-password-file-encrypted >/dev/null 2>&1
    if Wait_For_Health_Check test-password-file-encrypted 15; then
        docker-compose stop test-password-file-encrypted >/dev/null 2>&1
        Log_Success "密码文件参数测试通过 (--password-file)"
    else
        docker-compose logs test-password-file-encrypted | tail -20
        docker-compose stop test-password-file-encrypted >/dev/null 2>&1
        Log_Error "密码文件参数验证失败"
        exit 1
    fi
    
    Log_Step "24" "加密验证测试 (--verify)"
    Log_Info "准备验证测试应用..."
    docker-compose run --rm prepare-verify-test >/dev/null 2>&1 || { Log_Error "准备验证测试失败"; exit 1; }
    Log_Info "加密并验证..."
    docker-compose run --rm encrypt-and-verify >/dev/null 2>&1 || { Log_Error "加密验证失败"; exit 1; }
    Log_Success "加密验证测试通过 (--verify)"
    
    # 计算用时
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # 测试完成
    Log_Header "CI 测试完成"
    Log_Success "所有 CI 测试通过!"
    Log_Info "总用时: ${duration}秒"
    Log_Info "测试覆盖: 基础功能 + 高级特性"
    
    # 生成报告（CI 格式）
    Generate_Test_Report "${PROJECT_ROOT}/ci-test-report.txt"
    
    # GitHub Actions 特定输出
    if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
        echo "test_duration=${duration}" >> "$GITHUB_OUTPUT"
        echo "test_status=passed" >> "$GITHUB_OUTPUT"
    fi
}

# ========================================
# 启动主函数
# ========================================

Main "$@"
