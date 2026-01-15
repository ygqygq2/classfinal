#!/usr/bin/env bash
#
# 本地集成测试脚本
# Local Integration Test Script
#
# 功能：
# - 使用本地环境变量（SONATYPE_USERNAME, SONATYPE_PASSWORD）
# - 使用国内镜像源加速构建
# - 完整的加密测试流程
#
# 使用方法：
#   bash integration-test/run-local-tests.sh
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
# 权限修复（Docker生成的文件权限问题）
# ========================================

function Fix_Permissions() {
    # 仅在本地开发环境中修复权限（CI环境不需要）
    if [ "${CI:-false}" = "true" ] || [ "${GITHUB_ACTIONS:-false}" = "true" ]; then
        Log_Info "CI环境，跳过权限修复"
        return 0
    fi
    
    Log_Info "修复 Docker 生成的文件权限..."
    
    # 修复target目录权限（如果存在）
    if [ -d "classfinal-core/target" ]; then
        sudo chown -R "$(id -u):$(id -g)" classfinal-core/target 2>/dev/null || true
    fi
    if [ -d "classfinal-fatjar/target" ]; then
        sudo chown -R "$(id -u):$(id -g)" classfinal-fatjar/target 2>/dev/null || true
    fi
    if [ -d "classfinal-maven-plugin/target" ]; then
        sudo chown -R "$(id -u):$(id -g)" classfinal-maven-plugin/target 2>/dev/null || true
    fi
    
    # 修复集成测试目录权限
    if [ -d "integration-test/test-apps" ]; then
        sudo chown -R "$(id -u):$(id -g)" integration-test/test-apps 2>/dev/null || true
    fi
    
    Log_Success "权限修复完成"
}

# ========================================
# 环境检查
# ========================================

function Check_Local_Environment() {
    Log_Info "检查本地环境..."
    
    # 检查必需工具
    Check_Docker
    Check_Docker_Compose
    
    # 检查可选凭证
    Check_Sonatype_Credentials || Log_Warning "Maven 部署测试将跳过"
    
    Log_Success "本地环境检查完成"
}

# ========================================
# 本地配置
# ========================================

function Setup_Local_Config() {
    Log_Info "配置本地环境..."
    
    # 使用国内镜像源
    export USE_CHINA_MIRROR=true
    Log_Info "已启用国内镜像源"
    
    # 启用 Docker BuildKit
    export DOCKER_BUILDKIT=1
    export COMPOSE_DOCKER_CLI_BUILD=1
    Log_Info "已启用 Docker BuildKit"
    
    Log_Success "本地配置完成"
}

# ========================================
# 主测试流程
# ========================================

function Main() {
    Log_Header "ClassFinal 本地集成测试"
    
    local start_time=$(date +%s)
    
    # 修复权限（必须在测试开始前）
    Fix_Permissions
    
    # 环境检查
    Check_Local_Environment
    
    # 本地配置
    Setup_Local_Config
    
    # 执行完整测试流程（保持与原脚本一致）
    Log_Step "1" "构建 ClassFinal"
    Log_Info "开始构建 ClassFinal 镜像(可能需要几分钟)..."
    Docker_Compose build classfinal >/dev/null 2>&1
    Log_Success "ClassFinal 镜像构建成功"
    
    Log_Step "2" "构建测试应用"
    Log_Info "开始构建测试应用镜像..."
    Docker_Compose build test-app >/dev/null 2>&1
    Log_Success "测试应用镜像构建成功"
    
    Log_Step "3" "测试原始应用（未加密）"
    Docker_Compose up -d test-original >/dev/null 2>&1
    sleep 5
    if docker exec test-original sh -c "wget -q -O- http://localhost:8080/health 2>/dev/null || curl -sf http://localhost:8080/health" >/dev/null 2>&1; then
        Log_Success "原始应用运行正常"
    else
        Log_Error "原始应用健康检查失败"
        Docker_Compose logs test-original
        exit 1
    fi
    Docker_Compose stop test-original >/dev/null 2>&1
    
    Log_Step "4" "准备测试应用"
    Docker_Compose run --rm prepare-test-app >/dev/null 2>&1
    Log_Success "测试应用准备完成"
    
    Log_Step "5" "加密测试应用"
    Docker_Compose run --rm encrypt-app >/dev/null 2>&1
    Log_Success "应用加密成功"
    
    Log_Step "6" "测试无密码运行加密应用"
    temp_log=$(mktemp)
    Docker_Compose run --rm test-encrypted-no-password 2>&1 | tee "$temp_log"
    if grep -q "✓ 测试通过" "$temp_log"; then
        Log_Success "加密应用正确要求密码验证"
    else
        Log_Error "无密码测试失败"
        cat "$temp_log"
        rm -f "$temp_log"
        exit 1
    fi
    rm -f "$temp_log"
    
    Log_Step "7" "测试使用正确密码运行"
    Docker_Compose up -d test-encrypted-with-password >/dev/null 2>&1
    Log_Info "等待应用就绪..."
    if Wait_For_Health_Check test-encrypted-with-password 15; then
        Log_Success "健康检查成功"
    else
        Log_Error "健康检查超时"
        Docker_Compose logs test-encrypted-with-password | tail -20
        Docker_Compose stop test-encrypted-with-password >/dev/null 2>&1
        exit 1
    fi
    Log_Info "验证测试接口..."
    if docker exec test-encrypted-with-password sh -c "wget -q -O- http://localhost:8080/test 2>/dev/null || curl -sf http://localhost:8080/test" >/dev/null 2>&1; then
        Log_Success "测试接口成功"
    else
        Log_Error "测试接口失败"
        Docker_Compose logs test-encrypted-with-password | tail -20
        Docker_Compose stop test-encrypted-with-password >/dev/null 2>&1
        exit 1
    fi
    Docker_Compose stop test-encrypted-with-password >/dev/null 2>&1
    Log_Success "加密应用使用正确密码运行成功"
    
    Log_Step "8" "测试使用错误密码运行"
    temp_log=$(mktemp)
    Docker_Compose run --rm test-encrypted-wrong-password 2>&1 | tee "$temp_log"
    if grep -q "✓ 测试通过" "$temp_log"; then
        Log_Success "加密应用正确拒绝错误密码"
    else
        Log_Error "错误密码测试失败"
        cat "$temp_log"
        rm -f "$temp_log"
        exit 1
    fi
    rm -f "$temp_log"
    
    Log_Step "9" "准备多包加密测试"
    Docker_Compose run --rm prepare-multipackage-test >/dev/null 2>&1
    Log_Success "多包测试应用准备完成"
    
    Log_Step "10" "执行多包加密"
    Docker_Compose run --rm encrypt-multipackage >/dev/null 2>&1
    Log_Success "多包加密成功"
    
    Log_Step "11" "测试多包加密应用运行"
    Docker_Compose up -d test-multipackage-encrypted >/dev/null 2>&1
    if Wait_For_Health_Check test-multipackage-encrypted 15; then
        Docker_Compose stop test-multipackage-encrypted >/dev/null 2>&1
        Log_Success "多包加密应用运行成功"
    else
        Docker_Compose stop test-multipackage-encrypted >/dev/null 2>&1
        Log_Error "多包加密应用启动超时"
        exit 1
    fi
    
    Log_Step "12" "测试排除类名功能"
    Docker_Compose run --rm prepare-exclude-test >/dev/null 2>&1
    Docker_Compose run --rm encrypt-with-exclude >/dev/null 2>&1
    Docker_Compose up -d test-encrypted-with-exclude >/dev/null 2>&1
    if Wait_For_Health_Check test-encrypted-with-exclude 15; then
        Docker_Compose stop test-encrypted-with-exclude >/dev/null 2>&1
        Log_Success "排除类名功能测试通过"
    else
        Docker_Compose stop test-encrypted-with-exclude >/dev/null 2>&1
        Log_Error "排除类名功能启动超时"
        exit 1
    fi
    
    Log_Step "13" "测试无密码模式"
    Docker_Compose run --rm prepare-nopwd-test >/dev/null 2>&1
    Docker_Compose run --rm encrypt-nopwd >/dev/null 2>&1
    
    Log_Info "测试无密码模式运行（限时15秒）..."
    temp_log=$(mktemp)
    Docker_Compose run --rm test-encrypted-nopwd 2>&1 | tee "$temp_log"
    if grep -q "✓ 测试通过" "$temp_log"; then
        Log_Success "无密码模式测试通过"
    else
        Log_Error "无密码模式测试失败"
        cat "$temp_log"
        rm -f "$temp_log"
        exit 1
    fi
    rm -f "$temp_log"
    
    Log_Step "14" "安装 classfinal-maven-plugin 到本地仓库"
    Log_Info "开始安装 Maven 插件（可能需要几分钟，请耐心等待）..."
    temp_log=$(mktemp)
    if Docker_Compose run --rm install-maven-plugin 2>&1 | grep -v -E "^Downloading|^Downloaded|Progress \(|from central|from aliyunmaven" > "$temp_log"; then
        if grep -qE "✓.*已安装到本地仓库|BUILD SUCCESS" "$temp_log"; then
            Log_Success "Maven 插件安装完成"
        else
            Log_Warning "Maven 插件可能安装失败，检查输出："
            tail -20 "$temp_log"
        fi
    else
        Log_Error "Maven 插件安装失败"
        cat "$temp_log"
        rm -f "$temp_log"
        exit 1
    fi
    rm -f "$temp_log"
    
    Log_Step "15" "Maven 插件集成测试"
    Log_Info "构建并运行 Maven 插件测试应用（可能需要较长时间）..."
    temp_log=$(mktemp)
    if Docker_Compose run --rm test-maven-plugin 2>&1 | grep -v -E "^Downloading|^Downloaded|Progress \(|from central" > "$temp_log"; then
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
    Docker_Compose run --rm prepare-libjars-test >/dev/null 2>&1 || { Log_Error "准备 lib 依赖测试失败"; exit 1; }
    Docker_Compose run --rm encrypt-with-libjars >/dev/null 2>&1 || { Log_Error "lib 依赖加密失败"; exit 1; }
    Docker_Compose up -d test-libjars-encrypted >/dev/null 2>&1
    if Wait_For_Health_Check test-libjars-encrypted 15; then
        Docker_Compose stop test-libjars-encrypted >/dev/null 2>&1
        Log_Success "lib 依赖加密测试通过"
    else
        Docker_Compose stop test-libjars-encrypted >/dev/null 2>&1
        Log_Error "lib 依赖加密验证失败"
        exit 1
    fi
    
    Log_Step "17" "配置文件加密测试"
    Docker_Compose run --rm prepare-config-encryption >/dev/null 2>&1 || { Log_Error "准备配置加密测试失败"; exit 1; }
    Docker_Compose run --rm encrypt-config-files >/dev/null 2>&1 || { Log_Error "配置文件加密失败"; exit 1; }
    Docker_Compose up -d test-config-encrypted >/dev/null 2>&1
    if Wait_For_Health_Check test-config-encrypted 15; then
        Docker_Compose stop test-config-encrypted >/dev/null 2>&1
        Log_Success "配置文件加密测试通过"
    else
        Docker_Compose stop test-config-encrypted >/dev/null 2>&1
        Log_Error "配置文件加密验证失败"
        exit 1
    fi
    
    Log_Step "18" "机器码绑定测试"
    Docker_Compose run --rm prepare-machine-code >/dev/null 2>&1
    Docker_Compose run --rm encrypt-with-machine-code >/dev/null 2>&1
    
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
    Docker_Compose run --rm prepare-war-test >/dev/null 2>&1
    Docker_Compose run --rm encrypt-war >/dev/null 2>&1
    
    # test-war-encrypted 是一次性验证脚本，不是持续运行的服务
    if Docker_Compose run --rm test-war-encrypted >/dev/null 2>&1; then
        Log_Success "WAR 包加密测试通过"
    else
        Log_Error "WAR 包加密验证失败"
        # 显示详细错误信息
        Docker_Compose run --rm test-war-encrypted 2>&1 | tail -20
        exit 1
    fi
    
    Log_Step "20" "反编译保护验证测试"
    Docker_Compose run --rm prepare-decompile-test >/dev/null 2>&1
    Log_Success "反编译保护验证完成"
    
    Log_Step "21" "Maven 本地安装测试"
    Docker_Compose run --rm test-mvn-install >/dev/null 2>&1
    Log_Success "Maven 本地安装测试通过"
    
    Log_Step "22" "配置文件参数测试 (--config)"
    Log_Info "创建加密配置文件..."
    Docker_Compose run --rm prepare-config-param-test >/dev/null 2>&1 || { Log_Error "准备配置文件测试失败"; exit 1; }
    Log_Info "使用配置文件加密..."
    Docker_Compose run --rm encrypt-with-config-param >/dev/null 2>&1 || { Log_Error "配置文件参数加密失败"; exit 1; }
    Docker_Compose up -d test-config-param-encrypted >/dev/null 2>&1
    if Wait_For_Health_Check test-config-param-encrypted 15; then
        Docker_Compose stop test-config-param-encrypted >/dev/null 2>&1
        Log_Success "配置文件参数测试通过 (--config)"
    else
        Docker_Compose logs test-config-param-encrypted | tail -20
        Docker_Compose stop test-config-param-encrypted >/dev/null 2>&1
        Log_Error "配置文件参数验证失败"
        exit 1
    fi
    
    Log_Step "23" "密码文件参数测试 (--password-file)"
    Log_Info "创建密码文件..."
    Docker_Compose run --rm prepare-password-file-test >/dev/null 2>&1 || { Log_Error "准备密码文件测试失败"; exit 1; }
    Log_Info "使用密码文件加密..."
    Docker_Compose run --rm encrypt-with-password-file >/dev/null 2>&1 || { Log_Error "密码文件参数加密失败"; exit 1; }
    Docker_Compose up -d test-password-file-encrypted >/dev/null 2>&1
    if Wait_For_Health_Check test-password-file-encrypted 15; then
        Docker_Compose stop test-password-file-encrypted >/dev/null 2>&1
        Log_Success "密码文件参数测试通过 (--password-file)"
    else
        Docker_Compose logs test-password-file-encrypted | tail -20
        Docker_Compose stop test-password-file-encrypted >/dev/null 2>&1
        Log_Error "密码文件参数验证失败"
        exit 1
    fi
    
    Log_Step "24" "加密验证测试 (--verify)"
    Log_Info "准备验证测试应用..."
    Docker_Compose run --rm prepare-verify-test >/dev/null 2>&1 || { Log_Error "准备验证测试失败"; exit 1; }
    Log_Info "加密并验证..."
    Docker_Compose run --rm encrypt-and-verify >/dev/null 2>&1 || { Log_Error "加密验证失败"; exit 1; }
    Log_Success "加密验证测试通过 (--verify)"
    
    # 计算用时
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # 测试完成
    Log_Header "测试完成"
    Log_Success "所有本地测试通过!"
    Log_Info "总用时: ${duration}秒"
    Log_Info "测试覆盖: 基础功能 + 高级特性"
}

# ========================================
# 启动主函数
# ========================================

Main "$@"
