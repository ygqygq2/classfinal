#!/bin/bash
#
# HTTP 接口验证脚本
# Verify HTTP endpoints of encrypted applications
#
# 功能：
# - 验证加密应用的 HTTP 服务是否正常
# - 使用 curl 容器访问应用接口
#

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Docker Compose 兼容性包装函数
function Docker_Compose() {
    if type -P docker-compose >/dev/null 2>&1; then
        command docker-compose "$@"
    else
        docker compose "$@"
    fi
}

# 验证单个应用的 HTTP 接口
# 参数: $1 = 应用容器名称, $2 = 描述
function Verify_App_Http() {
    local app_container="$1"
    local description="$2"
    
    echo -e "${BLUE}ℹ${NC} 验证 ${description}..."
    
    # 启动应用容器（后台运行）
    Docker_Compose up -d "${app_container}"
    
    # 等待应用启动
    sleep 10
    
    # 使用 curl 容器验证接口
    set +e
    Docker_Compose run --rm verify-app-health \
        sh -c "curl -f http://${app_container}:8080/health && curl -f http://${app_container}:8080/test"
    result=$?
    set -e
    
    # 停止应用容器
    Docker_Compose stop "${app_container}"
    
    if [[ $result -eq 0 ]]; then
        echo -e "${GREEN}✓${NC} ${description} HTTP 接口验证通过"
        return 0
    else
        echo -e "${RED}✗${NC} ${description} HTTP 接口验证失败"
        return 1
    fi
}

# 主函数
function Main() {
    echo "========================================"
    echo "   HTTP 接口验证"
    echo "   HTTP Endpoint Verification"
    echo "========================================"
    
    # 创建临时 curl 验证容器服务
    cat > /tmp/verify-compose.yml <<'EOF'
services:
  verify-app-health:
    image: curlimages/curl:latest
    networks:
      - classfinal_test-network
    command: ["sh", "-c", "echo 'curl container ready'"]

networks:
  classfinal_test-network:
    external: true
EOF
    
    # 应该成功的容器列表
    declare -A SHOULD_SUCCEED=(
        ["test-encrypted-with-password"]="加密应用（正确密码）"
        ["test-multipackage-encrypted"]="多包加密应用"
        ["test-encrypted-with-exclude"]="排除类加密应用"
        ["test-maven-plugin"]="Maven插件加密应用"
        ["test-libjars-encrypted"]="Lib依赖加密应用"
        ["test-config-encrypted"]="配置文件加密应用"
        ["test-machine-code-correct"]="机器码绑定应用"
        ["test-war-encrypted"]="WAR包加密应用"
    )
    
    local failed=0
    local total=0
    
    for container in "${!SHOULD_SUCCEED[@]}"; do
        total=$((total + 1))
        if ! Verify_App_Http "${container}" "${SHOULD_SUCCEED[$container]}"; then
            failed=$((failed + 1))
        fi
    done
    
    # 清理临时文件
    rm -f /tmp/verify-compose.yml
    
    echo ""
    echo "========================================"
    echo "验证结果: $((total - failed))/${total} 通过"
    if [[ $failed -eq 0 ]]; then
        echo -e "${GREEN}✓ 所有 HTTP 接口验证通过${NC}"
        return 0
    else
        echo -e "${RED}✗ ${failed} 个接口验证失败${NC}"
        return 1
    fi
}

Main "$@"
