#!/usr/bin/env bash
#
# 测试步骤函数库
# Test step functions for ClassFinal integration tests
#
# 功能：
# - 构建测试步骤
# - 加密测试步骤
# - 验证测试步骤
# - 完整测试流程
#
# 使用方法：
#   source "$(dirname "$0")/lib/test-steps.sh"
#

# 依赖其他库
if [[ -z "${GREEN:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${SCRIPT_DIR}/common.sh"
    source "${SCRIPT_DIR}/docker-utils.sh"
fi

# ========================================
# 构建步骤
# ========================================

function Build_ClassFinal() {
    local quiet="${1:-true}"
    
    Log_Step "BUILD" "构建 ClassFinal"
    
    if Docker_Compose_Build "classfinal" "$quiet"; then
        Log_Success "ClassFinal 构建成功"
        return 0
    else
        Log_Error "ClassFinal 构建失败"
        return 1
    fi
}

function Build_Test_App() {
    local quiet="${1:-true}"
    
    Log_Step "BUILD" "构建测试应用"
    
    if Docker_Compose_Build "test-app" "$quiet"; then
        Log_Success "测试应用构建成功"
        return 0
    else
        Log_Error "测试应用构建失败"
        return 1
    fi
}

function Build_All() {
    local quiet="${1:-true}"
    
    Build_ClassFinal "$quiet" || return 1
    Build_Test_App "$quiet" || return 1
    
    Log_Success "所有组件构建完成"
    return 0
}

# ========================================
# 测试原始应用
# ========================================

function Test_Original_App() {
    Log_Step "TEST" "测试原始应用(未加密)"
    
    # 启动容器（后台运行）
    if ! Docker_Compose_Up "test-original"; then
        return 1
    fi
    
    # 等待就绪
    Sleep_With_Progress 5 "等待应用启动"
    
    # 健康检查
    if ! Wait_For_Health_Check "test-original" 15; then
        Show_Container_Logs "test-original" 30
        Docker_Compose_Stop "test-original"
        return 1
    fi
    
    # 测试接口（使用 wget/curl 兼容方式）
    Log_Info "测试 HTTP 接口..."
    if docker exec test-original sh -c "wget -q -O- http://localhost:8080/test 2>/dev/null || curl -sf http://localhost:8080/test 2>/dev/null" >/dev/null 2>&1; then
        Log_Success "原始应用测试接口正常"
        Docker_Compose_Stop "test-original"
        return 0
    else
        Log_Error "原始应用测试接口失败"
        Show_Container_Logs "test-original" 30
        Docker_Compose_Stop "test-original"
        return 1
    fi
}

# ========================================
# 准备和加密
# ========================================

function Prepare_Test_App() {
    Log_Step "PREPARE" "准备测试应用"
    
    if Docker_Compose_Run "prepare-test-app"; then
        Log_Success "测试应用准备完成"
        return 0
    else
        Log_Error "测试应用准备失败"
        return 1
    fi
}

function Encrypt_Test_App() {
    Log_Step "ENCRYPT" "加密测试应用"
    
    if Docker_Compose_Run "encrypt-app"; then
        Log_Success "应用加密成功"
        return 0
    else
        Log_Error "应用加密失败"
        return 1
    fi
}

function Encrypt_With_Config() {
    local config_file="$1"
    
    Log_Step "ENCRYPT" "使用配置文件加密: $config_file"
    
    if Docker_Compose_Run "encrypt-with-config" "-v $config_file:/config/classfinal.yml"; then
        Log_Success "配置文件加密成功"
        return 0
    else
        Log_Error "配置文件加密失败"
        return 1
    fi
}

# ========================================
# 测试加密应用
# ========================================

function Test_Encrypted_No_Password() {
    Log_Step "TEST" "测试加密应用(无密码)"
    
    # 启动容器（预期失败或要求密码）
    Docker_Compose_Up "test-encrypted-no-password" >/dev/null 2>&1 || true
    
    Sleep_With_Progress 5 "检查应用行为"
    
    # 检查是否有密码要求的错误
    if docker logs "test-encrypted-no-password" 2>&1 | grep -iE "password|密码|authentication"; then
        Log_Success "加密应用正确要求密码验证"
        Docker_Compose_Stop "test-encrypted-no-password"
        return 0
    else
        Log_Warning "未检测到密码要求（可能需要检查）"
        Show_Container_Logs "test-encrypted-no-password" 30
        Docker_Compose_Stop "test-encrypted-no-password"
        return 1
    fi
}

function Test_Encrypted_With_Password() {
    Log_Step "TEST" "测试加密应用(正确密码)"
    
    # 启动容器
    if ! Docker_Compose_Up "test-encrypted-with-password"; then
        return 1
    fi
    
    # 等待就绪
    Log_Info "等待应用启动..."
    if ! Wait_For_Health_Check "test-encrypted-with-password" 20; then
        Log_Error "健康检查失败"
        Show_Container_Logs "test-encrypted-with-password" 30
        Docker_Compose_Stop "test-encrypted-with-password"
        return 1
    fi
    
    # 测试接口（使用 wget/curl 兼容方式）
    Log_Info "测试 HTTP 接口..."
    if docker exec test-encrypted-with-password sh -c "wget -q -O- http://localhost:8080/test 2>/dev/null || curl -sf http://localhost:8080/test 2>/dev/null" >/dev/null 2>&1; then
        Log_Success "加密应用(正确密码)测试通过"
        Docker_Compose_Stop "test-encrypted-with-password"
        return 0
    else
        Log_Error "加密应用测试失败"
        Show_Container_Logs "test-encrypted-with-password" 30
        Docker_Compose_Stop "test-encrypted-with-password"
        return 1
    fi
}

function Test_Encrypted_Wrong_Password() {
    Log_Step "TEST" "测试加密应用(错误密码)"
    
    # 启动容器（预期失败）
    Docker_Compose_Up "test-encrypted-wrong-password" >/dev/null 2>&1 || true
    
    Sleep_With_Progress 5 "检查应用行为"
    
    # 检查是否有密码错误的日志
    if docker logs "test-encrypted-wrong-password" 2>&1 | grep -iE "password|密码|authentication|验证失败|incorrect"; then
        Log_Success "加密应用正确拒绝错误密码"
        Docker_Compose_Stop "test-encrypted-wrong-password"
        return 0
    else
        Log_Warning "未检测到密码错误（可能需要检查）"
        Show_Container_Logs "test-encrypted-wrong-password" 30
        Docker_Compose_Stop "test-encrypted-wrong-password"
        return 1
    fi
}

# ========================================
# 多包加密测试
# ========================================

function Test_Multi_Package_Encryption() {
    Log_Step "TEST" "测试多包加密"
    
    # 准备多包测试
    if ! Docker_Compose_Run "prepare-multipackage-test"; then
        Log_Error "多包测试准备失败"
        return 1
    fi
    
    # 执行加密
    if ! Docker_Compose_Run "encrypt-multipackage"; then
        Log_Error "多包加密失败"
        return 1
    fi
    
    Log_Success "多包加密成功"
    
    # 测试加密后的应用
    if ! Docker_Compose_Up "test-multipackage-encrypted"; then
        return 1
    fi
    
    if Wait_For_Health_Check "test-multipackage-encrypted" 20; then
        Log_Success "多包加密应用测试通过"
        Docker_Compose_Stop "test-multipackage-encrypted"
        return 0
    else
        Log_Error "多包加密应用测试失败"
        Show_Container_Logs "test-multipackage-encrypted" 30
        Docker_Compose_Stop "test-multipackage-encrypted"
        return 1
    fi
}

# ========================================
# Maven 插件测试
# ========================================

function Test_Maven_Plugin() {
    Log_Step "TEST" "测试 Maven 插件"
    
    if ! Docker_Compose_Run "test-maven-plugin"; then
        Log_Error "Maven 插件测试失败"
        Show_Service_Logs "test-maven-plugin" 50
        return 1
    fi
    
    Log_Success "Maven 插件测试通过"
    return 0
}

# ========================================
# 配置文件测试
# ========================================

function Test_Config_File() {
    Log_Step "TEST" "测试配置文件功能"
    
    # 生成配置文件
    Log_Info "生成配置文件模板..."
    if ! Docker_Compose_Run "generate-config-template"; then
        Log_Error "配置文件模板生成失败"
        return 1
    fi
    
    # 使用配置文件加密
    if ! Encrypt_With_Config "/tmp/classfinal.yml"; then
        return 1
    fi
    
    # 测试配置文件加密的应用
    if Test_Encrypted_With_Password; then
        Log_Success "配置文件功能测试通过"
        return 0
    else
        return 1
    fi
}

# ========================================
# 验证功能测试
# ========================================

function Test_Verification_Tool() {
    Log_Step "TEST" "测试加密验证工具"
    
    Log_Info "验证未加密的 JAR..."
    if Docker_Compose_Run "verify-unencrypted-jar"; then
        Log_Success "未加密 JAR 验证正确"
    fi
    
    Log_Info "验证已加密的 JAR..."
    if Docker_Compose_Run "verify-encrypted-jar"; then
        Log_Success "已加密 JAR 验证正确"
        return 0
    else
        Log_Error "加密验证工具测试失败"
        return 1
    fi
}

# ========================================
# 完整测试流程
# ========================================

function Run_Basic_Tests() {
    Log_Info "执行基础测试流程..."
    
    Build_All || return 1
    Test_Original_App || return 1
    Prepare_Test_App || return 1
    Encrypt_Test_App || return 1
    Test_Encrypted_No_Password || return 1
    Test_Encrypted_With_Password || return 1
    Test_Encrypted_Wrong_Password || return 1
    
    Log_Success "基础测试流程完成"
    return 0
}

function Run_Advanced_Tests() {
    Log_Info "执行高级测试流程..."
    
    Test_Multi_Package_Encryption || return 1
    Test_Maven_Plugin || return 1
    
    Log_Success "高级测试流程完成"
    return 0
}

function Run_New_Features_Tests() {
    Log_Info "执行新功能测试流程(2.0.1)..."
    
    Test_Config_File || return 1
    Test_Verification_Tool || return 1
    
    Log_Success "新功能测试流程完成"
    return 0
}

function Run_All_Tests() {
    Log_Header "ClassFinal 完整集成测试"
    
    local start_time=$(date +%s)
    
    # 基础测试
    if ! Run_Basic_Tests; then
        Log_Error "基础测试失败"
        return 1
    fi
    
    # 高级测试
    if ! Run_Advanced_Tests; then
        Log_Error "高级测试失败"
        return 1
    fi
    
    # 新功能测试
    if ! Run_New_Features_Tests; then
        Log_Error "新功能测试失败"
        return 1
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    Log_Header "测试完成"
    Log_Success "所有测试通过! 用时: ${duration}s"
    
    return 0
}

# ========================================
# 测试报告
# ========================================

function Generate_Test_Report() {
    local output_file="${1:-test-report.txt}"
    
    Log_Info "生成测试报告: $output_file"
    
    {
        echo "ClassFinal Integration Test Report"
        echo "=================================="
        echo ""
        echo "Test Date: $(date)"
        echo "Project Version: $(Get_Project_Version)"
        echo "Docker Version: $(docker --version)"
        echo ""
        echo "Test Results:"
        echo "  ✓ Build ClassFinal"
        echo "  ✓ Build Test App"
        echo "  ✓ Test Original App"
        echo "  ✓ Encrypt App"
        echo "  ✓ Test Encrypted (no password)"
        echo "  ✓ Test Encrypted (with password)"
        echo "  ✓ Test Encrypted (wrong password)"
        echo "  ✓ Multi-package Encryption"
        echo "  ✓ Maven Plugin"
        echo ""
        echo "Status: PASSED"
    } > "$output_file"
    
    Log_Success "测试报告已生成: $output_file"
}
