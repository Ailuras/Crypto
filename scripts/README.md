# MiniZinc 并行求解器性能测试

这个工具包含两个脚本，用于并行测试多个MiniZinc求解器的性能：

## 脚本说明

### `parallel.sh` - 并行调度脚本
负责将模型文件分批并启动多个并行任务。

### `run.sh` - 串行执行脚本  
负责对单个模型文件串行测试多个求解器，并将结果记录到log文件。

## 使用方法

### 基本用法
```bash
bash scripts/parallel.sh --models-dir test --timeout 60 --max-parallel 5
```

### 完整参数
```bash
bash scripts/parallel.sh \
    --models-dir benchmarks/CP \
    --solvers cp-sat,chuffed,choco \
    --timeout 300 \
    --output-dir results \
    --max-parallel 5
```

### 参数说明
- `--models-dir DIR`: 包含.mzn文件的目录 (默认: benchmarks/CP)
- `--solvers LIST`: 逗号分隔的求解器列表 (默认: cp-sat,chuffed,choco)  
- `--timeout SECONDS`: 每个求解器的超时时间 (默认: 300秒)
- `--output-dir DIR`: 输出目录 (默认: results)
- `--max-parallel N`: 最大并行任务数 (默认: 5)
- `-h, --help`: 显示帮助信息

## 输出文件

每次运行会在输出目录下创建一个带时间戳的文件夹，包含：

- `*.log`: 每个模型的详细日志文件，包含三个求解器的完整输出
- `detailed_results.json`: 详细的JSON格式结果
- `summary_report.txt`: 汇总报告，包含性能表格和成功率统计
- `run_info.txt`: 运行信息和配置

## 日志文件格式

每个.log文件包含：
```
MODEL: model_name
FILE: /path/to/model.mzn
TEST_START: timestamp
TIMEOUT: 30s
SOLVERS: cp-sat chuffed choco

===========================================================
SOLVER: cp-sat
MODEL: model.mzn
PATH: /path/to/model.mzn
TIMEOUT: 30
START_TIME: timestamp
-----------------------------------------------------------
[求解器输出]
-----------------------------------------------------------
END_TIME: timestamp
SOLVING_TIME: 0.123456
RESULT: SUCCESS
```

## 性能分析

汇总报告包含：
1. 性能表格：每个模型在各求解器上的求解时间
2. 成功率统计：每个求解器的成功率百分比

## 示例输出

```
Performance Summary (seconds):
----------------------------------------
Model                cp-sat     chuffed    choco     
----------------------------------------
coloring             0.318      0.147      0.764      
knapsack_problem     0.330      0.146      0.754      
magic_square         0.337      0.151      0.745      

Success Rate by Solver:
-------------------------
cp-sat         :  5/5 (100.0%)
chuffed        :  5/5 (100.0%)
choco          :  5/5 (100.0%)
```

## 注意事项

1. 确保所有求解器都已正确安装和配置
2. 根据服务器内存和CPU核心数调整 `--max-parallel` 参数
3. 对于大型模型，适当增加 `--timeout` 值
4. 脚本会自动处理.dzn数据文件（如果存在） 