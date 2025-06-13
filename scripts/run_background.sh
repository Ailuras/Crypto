#!/bin/bash

# MiniZinc Solver Background Runner
# 支持在macOS和Linux上后台运行求解器比较测试

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOG_DIR="$PROJECT_DIR/logs"
RESULTS_DIR="$PROJECT_DIR/results"

# 创建必要的目录
mkdir -p "$LOG_DIR"
mkdir -p "$RESULTS_DIR"

# 默认参数
MODELS_DIR="benchmarks/CP"
TIMEOUT=1800  # 30分钟
SOLVERS=""
OUTPUT_DIR="results"
USE_TMUX=false
SESSION_NAME="minizinc_comparison"

# 显示帮助信息
show_help() {
    cat << EOF
MiniZinc Solver Background Runner

Usage: $0 [OPTIONS]

Options:
    -h, --help              显示此帮助信息
    -m, --models-dir DIR    模型文件目录 (默认: benchmarks/CP)
    -t, --timeout SECONDS  超时时间秒数 (默认: 1800)
    -s, --solvers LIST      求解器列表，用空格分隔 (默认: 自动检测)
    -o, --output-dir DIR    输出目录 (默认: results)
    --tmux                  使用tmux会话运行 (推荐)
    --session-name NAME     tmux会话名称 (默认: minizinc_comparison)

Examples:
    # 基本用法 - 使用nohup后台运行
    $0

    # 使用tmux会话运行 (推荐)
    $0 --tmux

    # 指定特定求解器和超时时间
    $0 --solvers "coin-bc cp-sat" --timeout 3600

    # 使用自定义模型目录
    $0 --models-dir "my_models" --tmux

后台运行管理:
    # 查看nohup进程
    ps aux | grep compare_solvers.py

    # 查看tmux会话
    tmux list-sessions

    # 连接到tmux会话
    tmux attach-session -t $SESSION_NAME

    # 查看日志
    tail -f logs/comparison_*.log
EOF
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -m|--models-dir)
            MODELS_DIR="$2"
            shift 2
            ;;
        -t|--timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        -s|--solvers)
            SOLVERS="$2"
            shift 2
            ;;
        -o|--output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --tmux)
            USE_TMUX=true
            shift
            ;;
        --session-name)
            SESSION_NAME="$2"
            shift 2
            ;;
        *)
            echo "未知参数: $1"
            show_help
            exit 1
            ;;
    esac
done

# 检查Python和依赖
check_dependencies() {
    echo "检查依赖..."
    
    if ! command -v python3 &> /dev/null; then
        echo "错误: 未找到python3"
        exit 1
    fi
    
    if ! command -v minizinc &> /dev/null; then
        echo "错误: 未找到minizinc"
        exit 1
    fi
    
    # 检查Python包
    python3 -c "import pandas, subprocess, pathlib" 2>/dev/null || {
        echo "错误: 缺少Python依赖包 (pandas)"
        echo "请运行: pip3 install pandas"
        exit 1
    }
    
    echo "依赖检查通过"
}

# 构建命令
build_command() {
    local cmd="python3 $SCRIPT_DIR/compare_solvers.py"
    cmd="$cmd --models-dir $MODELS_DIR"
    cmd="$cmd --timeout $TIMEOUT"
    cmd="$cmd --output-dir $OUTPUT_DIR"
    
    if [[ -n "$SOLVERS" ]]; then
        cmd="$cmd --solvers $SOLVERS"
    fi
    
    # 在Linux环境中禁用emoji
    if [[ "$OSTYPE" == "linux-gnu"* ]] || [[ -n "$SSH_CONNECTION" ]]; then
        cmd="$cmd --no-emoji"
    fi
    
    echo "$cmd"
}

# 使用nohup后台运行
run_with_nohup() {
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local log_file="$LOG_DIR/comparison_${timestamp}.log"
    local pid_file="$LOG_DIR/comparison_${timestamp}.pid"
    
    echo "使用nohup后台运行..."
    echo "日志文件: $log_file"
    echo "PID文件: $pid_file"
    
    local cmd=$(build_command)
    
    # 切换到项目目录
    cd "$PROJECT_DIR"
    
    # 后台运行
    nohup $cmd > "$log_file" 2>&1 &
    local pid=$!
    
    echo $pid > "$pid_file"
    echo "进程已启动，PID: $pid"
    echo ""
    echo "监控命令:"
    echo "  查看日志: tail -f $log_file"
    echo "  查看进程: ps -p $pid"
    echo "  终止进程: kill $pid"
}

# 使用tmux运行
run_with_tmux() {
    echo "使用tmux会话运行..."
    
    # 检查tmux是否可用
    if ! command -v tmux &> /dev/null; then
        echo "错误: 未找到tmux"
        echo "请安装tmux: brew install tmux (macOS) 或 apt-get install tmux (Ubuntu)"
        exit 1
    fi
    
    # 检查会话是否已存在
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        echo "tmux会话 '$SESSION_NAME' 已存在"
        echo "选择操作:"
        echo "1) 连接到现有会话"
        echo "2) 终止现有会话并创建新会话"
        echo "3) 退出"
        read -p "请选择 (1-3): " choice
        
        case $choice in
            1)
                tmux attach-session -t "$SESSION_NAME"
                return
                ;;
            2)
                tmux kill-session -t "$SESSION_NAME"
                ;;
            3)
                exit 0
                ;;
            *)
                echo "无效选择"
                exit 1
                ;;
        esac
    fi
    
    local cmd=$(build_command)
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local log_file="$LOG_DIR/comparison_${timestamp}.log"
    
    # 创建新的tmux会话
    cd "$PROJECT_DIR"
    tmux new-session -d -s "$SESSION_NAME" -c "$PROJECT_DIR"
    
    # 在会话中运行命令并记录日志
    tmux send-keys -t "$SESSION_NAME" "$cmd | tee $log_file" Enter
    
    echo "tmux会话 '$SESSION_NAME' 已创建"
    echo "日志文件: $log_file"
    echo ""
    echo "管理命令:"
    echo "  连接会话: tmux attach-session -t $SESSION_NAME"
    echo "  查看会话: tmux list-sessions"
    echo "  终止会话: tmux kill-session -t $SESSION_NAME"
    echo "  查看日志: tail -f $log_file"
    echo ""
    echo "是否现在连接到会话? (y/n)"
    read -p "> " connect_now
    
    if [[ "$connect_now" =~ ^[Yy]$ ]]; then
        tmux attach-session -t "$SESSION_NAME"
    fi
}

# 主函数
main() {
    echo "MiniZinc Solver Background Runner"
    echo "================================="
    echo "操作系统: $OSTYPE"
    echo "模型目录: $MODELS_DIR"
    echo "超时时间: ${TIMEOUT}s"
    echo "输出目录: $OUTPUT_DIR"
    echo ""
    
    check_dependencies
    
    if [[ "$USE_TMUX" == true ]]; then
        run_with_tmux
    else
        run_with_nohup
    fi
}

# 运行主函数
main "$@" 