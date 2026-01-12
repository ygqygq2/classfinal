#!/usr/bin/env bash
#
# 通用函数库
# Common utility functions for integration tests
#
# 功能：
# - 日志输出（颜色、格式化）
# - 环境检查
# - Docker Compose 兼容性
# - 清理函数
#
# 使用方法：
#   source "$(dirname "$0")/lib/common.sh"
#

# 颜色定义
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export CYAN='\033[0;36m'
export NC='\033[0m'  # No Color

# ========================================
# 日志函数
# ========================================

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

function Log_Header() {
    local title="$1"
    echo ""
    echo "========================================="
    echo "   ${title}"
    echo "========================================="
    echo ""
}

# ========================================
# Docker Compose 兼容性
# ========================================

# Docker Compose V1/V2 兼容包装函数
function Docker_Compose() {
    if type -P docker-compose >/dev/null 2>&1; then
        command docker-compose "$@"
    else
        docker compose "$@"
    fi
}

# ========================================
# 环境检查
# ========================================

function Check_Command() {
    local cmd="$1"
    local package="${2:-$cmd}"
    
    if ! command -v "$cmd" &> /dev/null; then
        Log_Error "$cmd 未安装，请先安装 $package"
        return 1
    fi
    return 0
}

function Check_Docker() {
    if ! Check_Command docker "Docker"; then
        exit 1
    fi
    Log_Success "Docker 已安装: $(docker --version)"
}

function Check_Docker_Compose() {
    if ! Check_Command docker-compose "docker-compose" && ! docker compose version &> /dev/null; then
        Log_Error "docker-compose 未安装，请先安装 docker-compose"
        exit 1
    fi
    
    if type -P docker-compose >/dev/null 2>&1; then
        Log_Success "docker-compose 已安装: $(docker-compose --version)"
    else
        Log_Success "docker compose 已安装: $(docker compose version)"
    fi
}

function Check_Maven() {
    if ! Check_Command mvn "Maven"; then
        exit 1
    fi
    Log_Success "Maven 已安装: $(mvn --version | head -1)"
}

function Check_Java() {
    if ! Check_Command java "Java JDK"; then
        exit 1
    fi
    Log_Success "Java 已安装: $(java -version 2>&1 | head -1)"
}

# ========================================
# 环境变量
# ========================================

function Check_Env_Var() {
    local var_name="$1"
    local required="${2:-false}"
    
    if [[ -z "${!var_name:-}" ]]; then
        if [[ "$required" == "true" ]]; then
            Log_Error "$var_name 环境变量未设置"
            return 1
        else
            Log_Warning "$var_name 未设置"
            return 0
        fi
    else
        # 敏感信息只显示长度
        if [[ "$var_name" == *"PASSWORD"* ]] || [[ "$var_name" == *"TOKEN"* ]]; then
            local var_value="${!var_name}"
            Log_Success "$var_name 已设置 (长度: ${#var_value})"
        else
            Log_Success "$var_name 已设置: ${!var_name}"
        fi
    fi
    return 0
}

function Check_Sonatype_Credentials() {
    Log_Info "检查 Maven 凭证..."
    
    local has_username=false
    local has_password=false
    
    Check_Env_Var "SONATYPE_USERNAME" && has_username=true
    Check_Env_Var "SONATYPE_PASSWORD" && has_password=true
    
    if [[ "$has_username" == "false" ]] || [[ "$has_password" == "false" ]]; then
        Log_Warning "Maven Central 部署凭证未完整设置（部分测试将跳过）"
        return 1
    fi
    
    return 0
}

# ========================================
# 版本管理
# ========================================

function Get_Project_Version() {
    mvn help:evaluate -Dexpression=project.version -q -DforceStdout 2>/dev/null
}

function Get_Docker_Version() {
    local version=$(Get_Project_Version)
    echo "${version%-SNAPSHOT}"
}

# ========================================
# 清理函数
# ========================================

function Cleanup_Docker_Compose() {
    Log_Info "清理 Docker Compose 环境..."
    Docker_Compose down -v 2>/dev/null || true
    Log_Success "Docker Compose 清理完成"
}

function Cleanup_Docker_Images() {
    local pattern="${1:-classfinal}"
    Log_Info "清理 Docker 镜像 (pattern: $pattern)..."
    docker images | grep "$pattern" | awk '{print $3}' | xargs -r docker rmi -f 2>/dev/null || true
    Log_Success "Docker 镜像清理完成"
}

function Cleanup_Temp_Files() {
    Log_Info "清理临时文件..."
    find /tmp -name "classfinal-test-*" -type f -mmin +60 -delete 2>/dev/null || true
    Log_Success "临时文件清理完成"
}

function Cleanup_All() {
    Cleanup_Docker_Compose
    # Cleanup_Docker_Images  # 可选：清理镜像
    Cleanup_Temp_Files
}

# ========================================
# 错误处理
# ========================================

function Setup_Error_Trap() {
    trap 'Handle_Error $? $LINENO' ERR
}

function Handle_Error() {
    local exit_code=$1
    local line_number=$2
    
    Log_Error "脚本在第 $line_number 行失败 (退出码: $exit_code)"
    Cleanup_All
    exit "$exit_code"
}

# ========================================
# 文件检查
# ========================================

function Check_File_Exists() {
    local file="$1"
    local description="${2:-文件}"
    
    if [[ ! -f "$file" ]]; then
        Log_Error "$description 不存在: $file"
        return 1
    fi
    Log_Success "$description 存在: $file"
    return 0
}

function Check_Dir_Exists() {
    local dir="$1"
    local description="${2:-目录}"
    
    if [[ ! -d "$dir" ]]; then
        Log_Error "$description 不存在: $dir"
        return 1
    fi
    Log_Success "$description 存在: $dir"
    return 0
}

# ========================================
# 时间和重试
# ========================================

function Sleep_With_Progress() {
    local seconds="$1"
    local message="${2:-等待}"
    
    Log_Info "$message ($seconds 秒)..."
    for i in $(seq 1 "$seconds"); do
        echo -n "."
        sleep 1
    done
    echo ""
}

function Retry_Command() {
    local max_attempts="$1"
    local interval="$2"
    shift 2
    local cmd="$*"
    
    local attempt=1
    while [[ $attempt -le $max_attempts ]]; do
        if eval "$cmd"; then
            return 0
        fi
        
        if [[ $attempt -lt $max_attempts ]]; then
            Log_Warning "命令失败 (尝试 $attempt/$max_attempts)，${interval}秒后重试..."
            sleep "$interval"
        fi
        
        attempt=$((attempt + 1))
    done
    
    Log_Error "命令在 $max_attempts 次尝试后仍然失败"
    return 1
}

# ========================================
# 初始化函数
# ========================================

function Init_Common_Library() {
    # 设置错误处理
    set -euo pipefail
    
    # 获取项目根目录
    if [[ -z "${PROJECT_ROOT:-}" ]]; then
        if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
            local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
            export PROJECT_ROOT="$(cd "${script_dir}/../.." && pwd)"
        else
            export PROJECT_ROOT="$(pwd)"
        fi
    fi
    
    # 切换到项目根目录
    cd "$PROJECT_ROOT"
    
    # 设置清理陷阱
    trap Cleanup_All EXIT
}

# ========================================
# 主初始化
# ========================================

# 如果脚本被 source，自动初始化
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # 被 source 调用
    Init_Common_Library
fi
