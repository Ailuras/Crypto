# MiniZinc 求解器比较工具

这个目录包含了用于比较MiniZinc求解器性能的工具。

## 🛠️ 工具说明

### 1. `compare_solvers.py` - 求解器性能比较脚本

**功能**: 自动测试多个求解器在不同模型上的性能表现

**特性**:
- ✅ 自动发现模型文件
- ✅ 自动检测可用求解器
- ✅ 跨平台兼容 (macOS/Linux)
- ✅ 智能emoji检测 (Linux服务器环境自动禁用)
- ✅ 详细的结果记录和统计
- ✅ 超时控制和错误处理

**基本用法**:
```bash
# 使用默认设置
python3 scripts/compare_solvers.py

# 指定模型目录和超时时间
python3 scripts/compare_solvers.py --models-dir benchmarks/CP --timeout 300

# 指定特定求解器
python3 scripts/compare_solvers.py --solvers "coin-bc cp-sat"

# Linux环境禁用emoji
python3 scripts/compare_solvers.py --no-emoji
```

### 2. `run_background.sh` - 后台运行管理脚本

**功能**: 在后台运行长时间的求解器比较测试

**支持的后台方式**:
- **nohup**: 基本后台运行 (默认)
- **tmux**: 会话管理 (推荐)

**基本用法**:
```bash
# 使用nohup后台运行
./scripts/run_background.sh

# 使用tmux会话运行 (推荐)
./scripts/run_background.sh --tmux

# 指定参数
./scripts/run_background.sh --timeout 3600 --solvers "coin-bc cp-sat" --tmux
```

### 3. `test_solvers.sh` - 简单测试脚本

**功能**: 快速测试基本模型和可用求解器

**用法**:
```bash
./scripts/test_solvers.sh
```

## 📋 使用场景

### 场景1: 快速验证求解器安装
```bash
./scripts/test_solvers.sh
```

### 场景2: 本地短时间性能测试
```bash
python3 scripts/compare_solvers.py --timeout 300
```

### 场景3: 服务器长时间基准测试
```bash
# 使用tmux会话
./scripts/run_background.sh --tmux --timeout 7200

# 或使用nohup
./scripts/run_background.sh --timeout 7200
```

### 场景4: Linux服务器环境
```bash
# 自动禁用emoji，使用nohup
./scripts/run_background.sh --timeout 3600

# 手动禁用emoji
python3 scripts/compare_solvers.py --no-emoji --timeout 600
```

## 🔧 后台运行管理

### 使用tmux (推荐)

**优点**:
- 可以随时连接/断开会话
- 支持多窗口和分屏
- 会话持久化，即使SSH断开也继续运行

```bash
# 启动tmux会话
./scripts/run_background.sh --tmux

# 查看所有会话
tmux list-sessions

# 连接到会话
tmux attach-session -t minizinc_comparison

# 断开会话 (在tmux内按 Ctrl+B, 然后按 D)

# 终止会话
tmux kill-session -t minizinc_comparison
```

### 使用nohup

**优点**:
- 简单易用，无需额外软件
- 适合一次性运行

```bash
# 启动后台进程
./scripts/run_background.sh

# 查看进程
ps aux | grep compare_solvers.py

# 查看日志
tail -f logs/comparison_*.log

# 终止进程
kill <PID>
```

## 📊 结果文件

运行后会生成以下文件:

```
results/
├── detailed_results.json    # 详细结果 (JSON格式)
├── solver_comparison.csv    # 汇总表格 (CSV格式)

logs/
├── comparison_YYYYMMDD_HHMMSS.log  # 运行日志
├── comparison_YYYYMMDD_HHMMSS.pid  # 进程ID (nohup模式)
```

## 🐧 Linux兼容性

脚本已针对Linux环境进行优化:

1. **自动检测环境**: 在SSH连接或Linux终端中自动禁用emoji
2. **纯文本输出**: 使用 `[OK]`, `[FAIL]`, `[TIMEOUT]` 等标识符
3. **强制禁用**: 使用 `--no-emoji` 参数

**Linux环境变量检测**:
- `SSH_CONNECTION` - SSH连接
- `SSH_CLIENT` - SSH客户端
- `TERM` - 终端类型 (screen, tmux, linux)

## 💡 最佳实践

1. **短期测试**: 使用 `compare_solvers.py` 直接运行
2. **长期测试**: 使用 `run_background.sh --tmux`
3. **服务器环境**: 确保使用 `--no-emoji` 或让脚本自动检测
4. **大型基准测试**: 设置合理的超时时间 (1-2小时)
5. **监控进度**: 定期查看日志文件

## 🔍 故障排除

### 常见问题

1. **pandas未安装**:
   ```bash
   pip3 install pandas
   ```

2. **tmux未安装**:
   ```bash
   # macOS
   brew install tmux
   
   # Ubuntu/Debian
   sudo apt-get install tmux
   ```

3. **权限问题**:
   ```bash
   chmod +x scripts/*.sh
   ```

4. **emoji显示问题**:
   ```bash
   # 手动禁用emoji
   python3 scripts/compare_solvers.py --no-emoji
   ``` 