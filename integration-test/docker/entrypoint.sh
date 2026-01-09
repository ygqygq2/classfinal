#!/bin/sh
set -e

# 通用的 Java 应用启动脚本
# 支持以下模式：
# - encrypt: 加密模式
# - decrypt: 解密模式  
# - run: 普通运行模式
# - agent: JavaAgent 模式
# - 自定义命令：直接执行传入的命令

# 如果第一个参数不是预定义模式，则作为自定义命令执行
if [ $# -eq 0 ]; then
  MODE="run"
else
  MODE="$1"
fi

case "$MODE" in
  encrypt)
    echo "=== ClassFinal 加密模式 ==="
    
    # 必需的环境变量检查
    : "${INPUT_FILE:?环境变量 INPUT_FILE 未设置}"
    : "${PACKAGES:?环境变量 PACKAGES 未设置}"
    
    # 可选环境变量
    PASSWORD="${PASSWORD:-}"
    OUTPUT_FILE="${OUTPUT_FILE:-${INPUT_FILE%.*}-encrypted.jar}"
    
    # 构建加密命令
    CMD="java -jar /app/app.jar -file $INPUT_FILE -packages $PACKAGES"
    
    if [ -n "$PASSWORD" ]; then
      CMD="$CMD -pwd $PASSWORD"
    fi
    
    CMD="$CMD -Y"
    
    echo "执行: $CMD"
    eval $CMD
    ;;
    
  run)
    echo "=== 普通运行模式 ==="
    shift
    exec java -jar /app/app.jar "$@"
    ;;
    
  agent)
    echo "=== JavaAgent 模式 ==="
    : "${TARGET_JAR:?环境变量 TARGET_JAR 未设置}"
    
    # 构建 javaagent 参数
    # javaagent 参数格式: -javaagent:jar='参数' 
    # 参数之间用空格分隔，整个参数用单引号包裹
    AGENT_ARGS=""
    if [ -n "$PASSWORD" ]; then
      # 通过 -pwdname 参数指定环境变量名，让 CoreAgent 读取 PASSWORD 环境变量
      AGENT_ARGS="='-pwdname PASSWORD'"
    fi
    
    eval "java -javaagent:/app/app.jar${AGENT_ARGS} -jar \"$TARGET_JAR\""
    ;;
    
  *)
    # 自定义命令模式 - 直接执行传入的命令
    echo "=== 自定义命令模式 ==="
    exec "$@"
    ;;
esac
