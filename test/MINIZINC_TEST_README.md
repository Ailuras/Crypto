# MiniZinc 求解器测试套件

这个目录包含了用于测试MiniZinc求解器的简单模型文件和测试脚本。

## 文件说明

### MiniZinc 模型文件（位于 test/ 目录）

1. **simple_sudoku.mzn** - 简单的3x3数独问题
2. **magic_square.mzn** - 3x3魔方阵问题
3. **n_queens.mzn** - 8皇后问题
4. **coloring.mzn** - 图着色问题（5个节点，3种颜色）
5. **knapsack_problem.mzn** - 背包优化问题
6. **knapsack_problem.dzn** - 背包问题的数据文件

### 测试脚本（位于 scripts/ 目录）

1. **test_solvers.sh** - 综合测试脚本，自动检测可用求解器并测试所有模型

## 使用方法

### 运行测试脚本
```bash
./scripts/test_solvers.sh
```

### 手动测试单个模型
```bash
# 测试数独问题
minizinc --solver coin-bc test/simple_sudoku.mzn

# 测试魔方阵
minizinc --solver coin-bc test/magic_square.mzn

# 测试背包问题
minizinc --solver coin-bc test/knapsack_problem.mzn test/knapsack_problem.dzn
```

## 当前可用的求解器

根据你的安装，目前可用的求解器：
- **coin-bc** ✅ - COIN-OR的线性规划求解器（已测试工作正常）
- **cp-sat** ✅ - Google OR Tools的约束编程求解器（已测试工作正常）

其他求解器状态：
- **cplex** ❌ - 需要安装CPLEX动态库
- **gurobi** ❌ - 需要安装Gurobi动态库  
- **highs** ❌ - 需要安装HiGHS库
- **scip** ❌ - 需要安装SCIP库
- **xpress** ❌ - 需要安装Xpress库

## 安装更多求解器

```bash
# 安装Gecode约束编程求解器（推荐）
brew install minizinc-gecode

# 安装HiGHS线性规划求解器
brew install highs

# 检查安装后的可用求解器
minizinc --solvers
```

## 测试结果

最新测试结果：
- ✅ 数独问题 - 成功求解（coin-bc + cp-sat）
- ✅ 魔方阵问题 - 成功求解（coin-bc + cp-sat）
- ✅ N皇后问题 - 成功求解（coin-bc + cp-sat）
- ✅ 图着色问题 - 成功求解（coin-bc + cp-sat）
- ✅ 背包优化问题 - 成功求解（coin-bc + cp-sat）

成功率：100% (10/10) - 两个求解器都完美运行

## 模型说明

### 数独问题 (simple_sudoku.mzn)
- 3x3数独网格，每个3x3子网格、每行、每列都包含1-9的数字
- 使用`alldifferent`约束确保数字不重复

### 魔方阵 (magic_square.mzn)  
- 3x3魔方阵，每行、每列、两条对角线的和都相等
- 所有数字1-9都只出现一次

### N皇后问题 (n_queens.mzn)
- 8x8棋盘上放置8个皇后
- 确保没有两个皇后在同一行、列或对角线上
- 输出皇后在每行的列位置

### 图着色问题 (coloring.mzn)
- 5个节点的图，使用3种颜色着色
- 相邻节点不能使用相同颜色

### 背包问题 (knapsack_problem.mzn + knapsack_problem.dzn)
- 5个物品的0-1背包优化问题
- 目标是在容量限制下最大化价值
- 当前配置：容量15，最优解价值19 