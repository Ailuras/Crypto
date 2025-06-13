#!/bin/bash
echo "MiniZinc Solver Test Script"
echo "=========================="
echo ""
echo "Checking MiniZinc installation..."
if ! command -v minizinc &> /dev/null; then
    echo "❌ MiniZinc is not installed or not in PATH"
    exit 1
fi
echo "✅ MiniZinc is installed: $(minizinc --version | head -1)"
echo ""
echo "Available solvers:"
echo "=================="
minizinc --solvers
echo ""
echo "Detecting available CP solvers..."
echo "================================="

# 获取实际存在的fzn-xxx可执行文件
actual_fzn_solvers=()
for fzn in "$MINIZINC_BIN"/fzn-*; do
    [ -x "$fzn" ] || continue
    solver_name=$(basename "$fzn" | sed 's/^fzn-//')
    actual_fzn_solvers+=("$solver_name")
done

# 检测CP求解器并与实际可用fzn-xxx交集
cp_solvers=("cp-sat" "chuffed" "choco")
echo "Using fixed CP solvers: ${cp_solvers[*]}"
echo ""

if [ ${#cp_solvers[@]} -eq 0 ]; then
    echo "❌ No usable CP solvers found"
    exit 1
fi
echo "Found usable CP solvers: ${cp_solvers[*]}"
echo ""
echo "Testing CP solvers..."
echo "===================="
models=(
    "test/simple_sudoku.mzn:Simple 3x3 Sudoku"
    "test/magic_square.mzn:3x3 Magic Square"
    "test/n_queens.mzn:8 Queens Problem"
    "test/coloring.mzn:Graph Coloring"
    "test/knapsack_problem.mzn:Knapsack Optimization:test/knapsack_problem.dzn"
)
test_count=0
success_count=0
for solver in "${cp_solvers[@]}"; do
    echo "🔧 Testing solver: $solver"
    echo "================================"
    
    for model_info in "${models[@]}"; do
        IFS=':' read -r model_file description data_file <<< "$model_info"
        
        echo "Testing: $description"
        echo "File: $model_file"
        
        if [ ! -f "$model_file" ]; then
            echo "❌ Model file not found: $model_file"
            continue
        fi
        
        cmd="minizinc --solver $solver $model_file"
        if [ -n "$data_file" ] && [ -f "$data_file" ]; then
            cmd="$cmd $data_file"
        fi
        
        echo "Running: $cmd"
        
        output=$(timeout 30s $cmd 2>&1)
        exit_code=$?
        
        test_count=$((test_count + 1))
        
        if [ $exit_code -eq 0 ]; then
            echo "✅ SUCCESS"
            echo "Output (first 5 lines):"
            echo "$output" | head -5
            success_count=$((success_count + 1))
        elif [ $exit_code -eq 124 ]; then
            echo "⏰ TIMEOUT (30 seconds)"
        else
            echo "❌ FAILED (exit code: $exit_code)"
            echo "Error:"
            echo "$output" | head -3
        fi
        echo ""
    done
done
echo "Summary:"
echo "========"
echo "Tests run: $test_count"
echo "Successful: $success_count"
echo "Success rate: $(( success_count * 100 / test_count ))%"
echo ""
echo "💡 Available CP solvers tested: ${cp_solvers[*]}"
echo ""
echo "Test completed!" 