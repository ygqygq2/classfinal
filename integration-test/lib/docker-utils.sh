#!/usr/bin/env bash
#
# Docker 工具函数库
# Docker utilities for integration tests
#
# 功能：
# - 容器健康检查
# - HTTP 接口测试
# - Docker Compose 操作封装
# - 容器日志查看
#
# 使用方法：
#   source "$(dirname "$0")/lib/docker-utils.sh"
#

# 依赖 common.sh
if [[ -z "${GREEN:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${SCRIPT_DIR}/common.sh"
fi

# ========================================
# 容器健康检查
# ========================================

function Wait_For_Container_Ready() {
    local container_name="$1"
    local max_wait="${2:-30}"
    local check_interval="${3:-1}"
    
    Log_Info "等待容器就绪: $container_name (最长 ${max_wait}s)..."
    
    local elapsed=0
    while [[ $elapsed -lt $max_wait ]]; do
        if docker ps | grep -q "$container_name"; then
            Log_Success "容器 $container_name 已启动"
            return 0
        fi
        sleep "$check_interval"
        elapsed=$((elapsed + check_interval))
    done
    
    Log_Error "容器 $container_name 启动超时"
    return 1
}

function Wait_For_Health_Check() {
    local container_name="$1"
    local max_wait="${2:-30}"
    local endpoint="${3:-http://localhost:8080/health}"
    
    Log_Info "等待健康检查: $container_name..."
    
    local elapsed=0
    local interval=1
    
    while [[ $elapsed -lt $max_wait ]]; do
        # 尝试 curl 或 wget
        if docker exec "$container_name" sh -c "curl -sf $endpoint 2>/dev/null || wget -q -O- $endpoint 2>/dev/null" >/dev/null 2>&1; then
            Log_Success "健康检查通过: $container_name"
            return 0
        fi
        
        sleep "$interval"
        elapsed=$((elapsed + interval))
    done
    
    Log_Error "健康检查超时: $container_name"
    return 1
}

function Wait_For_Log_Message() {
    local container_name="$1"
    local message="$2"
    local max_wait="${3:-30}"
    
    Log_Info "等待日志消息: \"$message\"..."
    
    local elapsed=0
    local interval=1
    
    while [[ $elapsed -lt $max_wait ]]; do
        if docker logs "$container_name" 2>&1 | grep -q "$message"; then
            Log_Success "日志消息已出现: \"$message\""
            return 0
        fi
        
        sleep "$interval"
        elapsed=$((elapsed + interval))
    done
    
    Log_Error "等待日志消息超时: \"$message\""
    return 1
}

# ========================================
# HTTP 接口测试
# ========================================

function Test_HTTP_Endpoint() {
    local container_name="$1"
    local endpoint="$2"
    local expected_status="${3:-200}"
    local description="${4:-HTTP endpoint}"
    
    Log_Info "测试 $description: $endpoint"
    
    # 检查容器是否运行
    if ! docker ps | grep -q "$container_name"; then
        Log_Error "容器未运行: $container_name"
        return 1
    fi
    
    # 测试端点
    local response
    response=$(docker exec "$container_name" sh -c "curl -s -o /dev/null -w '%{http_code}' $endpoint 2>/dev/null" || echo "000")
    
    if [[ "$response" == "$expected_status" ]]; then
        Log_Success "$description 测试通过 (HTTP $response)"
        return 0
    else
        Log_Error "$description 测试失败 (期望: $expected_status, 实际: $response)"
        return 1
    fi
}

function Test_HTTP_Content() {
    local container_name="$1"
    local endpoint="$2"
    local expected_content="$3"
    local description="${4:-HTTP content}"
    
    Log_Info "测试 $description: $endpoint"
    
    local content
    content=$(docker exec "$container_name" sh -c "curl -sf $endpoint 2>/dev/null || wget -q -O- $endpoint 2>/dev/null" || echo "")
    
    if echo "$content" | grep -q "$expected_content"; then
        Log_Success "$description 包含期望内容: \"$expected_content\""
        return 0
    else
        Log_Error "$description 不包含期望内容: \"$expected_content\""
        Log_Info "实际内容: $content"
        return 1
    fi
}

# ========================================
# Docker Compose 操作
# ========================================

function Docker_Compose_Build() {
    local service="$1"
    local quiet="${2:-false}"
    
    Log_Info "构建服务: $service"
    
    if [[ "$quiet" == "true" ]]; then
        # 完全静默模式
        Docker_Compose build "$service" >/dev/null 2>&1
    else
        # 显示构建过程，但过滤 Maven 下载日志
        Docker_Compose build "$service" 2>&1 | grep -v -E "^Downloading|^Downloaded|Progress \(|from central"
    fi
    
    if [[ $? -eq 0 ]]; then
        Log_Success "服务构建成功: $service"
        return 0
    else
        Log_Error "服务构建失败: $service"
        return 1
    fi
}

function Docker_Compose_Up() {
    local service="$1"
    local detach="${2:-true}"
    
    Log_Info "启动服务: $service"
    
    if [[ "$detach" == "true" ]]; then
        Docker_Compose up -d "$service" >/dev/null 2>&1
    else
        Docker_Compose up "$service"
    fi
    
    if [[ $? -eq 0 ]]; then
        Log_Success "服务启动成功: $service"
        return 0
    else
        Log_Error "服务启动失败: $service"
        return 1
    fi
}

function Docker_Compose_Run() {
    local service="$1"
    shift
    local extra_args="$*"
    
    Log_Info "运行服务: $service $extra_args"
    
    Docker_Compose run --rm $extra_args "$service"
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        Log_Success "服务执行成功: $service"
        return 0
    else
        Log_Error "服务执行失败: $service (退出码: $exit_code)"
        return $exit_code
    fi
}

function Docker_Compose_Stop() {
    local service="$1"
    
    Log_Info "停止服务: $service"
    Docker_Compose stop "$service" >/dev/null 2>&1
    Log_Success "服务已停止: $service"
}

function Docker_Compose_Down() {
    Log_Info "停止所有服务..."
    Docker_Compose down -v 2>/dev/null || true
    Log_Success "所有服务已停止"
}

# ========================================
# 容器日志
# ========================================

function Show_Container_Logs() {
    local container_name="$1"
    local lines="${2:-50}"
    local description="${3:-容器}"
    
    Log_Info "$description 日志 (最后 $lines 行):"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    docker logs "$container_name" 2>&1 | tail -"$lines"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

function Show_Service_Logs() {
    local service="$1"
    local lines="${2:-50}"
    local description="${3:-服务}"
    
    Log_Info "$description 日志 (最后 $lines 行):"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Docker_Compose logs --tail="$lines" "$service" 2>&1
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

function Check_Logs_For_Error() {
    local container_name="$1"
    local error_pattern="${2:-ERROR|Exception|Failed}"
    
    if docker logs "$container_name" 2>&1 | grep -iE "$error_pattern" >/dev/null; then
        Log_Warning "容器日志包含错误信息:"
        docker logs "$container_name" 2>&1 | grep -iE "$error_pattern" | tail -10
        return 1
    fi
    return 0
}

# ========================================
# 容器操作
# ========================================

function Exec_In_Container() {
    local container_name="$1"
    shift
    local command="$*"
    
    docker exec "$container_name" sh -c "$command"
}

function Copy_From_Container() {
    local container_name="$1"
    local src="$2"
    local dest="$3"
    
    Log_Info "从容器复制: $container_name:$src -> $dest"
    docker cp "$container_name:$src" "$dest"
    
    if [[ $? -eq 0 ]]; then
        Log_Success "文件复制成功"
        return 0
    else
        Log_Error "文件复制失败"
        return 1
    fi
}

function Copy_To_Container() {
    local container_name="$1"
    local src="$2"
    local dest="$3"
    
    Log_Info "复制到容器: $src -> $container_name:$dest"
    docker cp "$src" "$container_name:$dest"
    
    if [[ $? -eq 0 ]]; then
        Log_Success "文件复制成功"
        return 0
    else
        Log_Error "文件复制失败"
        return 1
    fi
}

# ========================================
# 容器信息
# ========================================

function Get_Container_Status() {
    local container_name="$1"
    
    docker inspect -f '{{.State.Status}}' "$container_name" 2>/dev/null || echo "not-found"
}

function Is_Container_Running() {
    local container_name="$1"
    
    local status
    status=$(Get_Container_Status "$container_name")
    
    [[ "$status" == "running" ]]
}

function Get_Container_IP() {
    local container_name="$1"
    
    docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_name" 2>/dev/null
}

function Get_Container_Port() {
    local container_name="$1"
    local internal_port="${2:-8080}"
    
    docker port "$container_name" "$internal_port" 2>/dev/null | cut -d: -f2
}

# ========================================
# 测试辅助函数
# ========================================

function Test_Container_Responds() {
    local container_name="$1"
    local max_wait="${2:-30}"
    
    if ! Wait_For_Container_Ready "$container_name" "$max_wait"; then
        return 1
    fi
    
    if ! Wait_For_Health_Check "$container_name" "$max_wait"; then
        Show_Container_Logs "$container_name" 30 "失败容器"
        return 1
    fi
    
    return 0
}

function Test_Encrypted_App() {
    local container_name="$1"
    local with_password="${2:-true}"
    local max_wait="${3:-15}"
    
    if [[ "$with_password" == "true" ]]; then
        Log_Info "测试加密应用(带密码): $container_name"
    else
        Log_Info "测试加密应用(无密码): $container_name"
    fi
    
    # 启动容器
    if ! Docker_Compose_Up "$container_name"; then
        return 1
    fi
    
    # 等待并测试
    if [[ "$with_password" == "true" ]]; then
        if Test_Container_Responds "$container_name" "$max_wait"; then
            Log_Success "加密应用测试通过(带密码)"
            return 0
        else
            Log_Error "加密应用测试失败(带密码)"
            return 1
        fi
    else
        # 无密码应该失败
        sleep 5
        if Check_Logs_For_Error "$container_name"; then
            Log_Error "加密应用应该要求密码，但未发现错误"
            return 1
        else
            Log_Success "加密应用正确要求密码验证"
            return 0
        fi
    fi
}
