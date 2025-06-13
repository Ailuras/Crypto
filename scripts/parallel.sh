#!/bin/bash

# Parallel solver comparison script
# Usage: parallel.sh [options]

# Default values
MODELS_DIR="benchmarks/CP"
SOLVERS=("cp-sat" "chuffed" "choco")
TIMEOUT=300
OUTPUT_DIR="results"
MAX_PARALLEL=5
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RUN_DIR="$OUTPUT_DIR/run_$TIMESTAMP"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --models-dir)
            MODELS_DIR="$2"
            shift 2
            ;;
        --solvers)
            IFS=',' read -ra SOLVERS <<< "$2"
            shift 2
            ;;
        --timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --max-parallel)
            MAX_PARALLEL="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --models-dir DIR     Directory containing .mzn files (default: benchmarks/CP)"
            echo "  --solvers LIST       Comma-separated list of solvers (default: cp-sat,chuffed,choco)"
            echo "  --timeout SECONDS    Timeout per solver (default: 300)"
            echo "  --output-dir DIR     Output directory (default: results)"
            echo "  --max-parallel N     Maximum parallel tasks (default: 5)"
            echo "  -h, --help          Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown parameter: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Check if models directory exists
if [ ! -d "$MODELS_DIR" ]; then
    echo "Error: Models directory not found: $MODELS_DIR"
    exit 1
fi

# Create output directory
mkdir -p "$RUN_DIR"

# Find all .mzn files
mapfile -t MODEL_FILES < <(find "$MODELS_DIR" -name "*.mzn" -type f | sort)

if [ ${#MODEL_FILES[@]} -eq 0 ]; then
    echo "Error: No .mzn files found in $MODELS_DIR"
    exit 1
fi

echo "MiniZinc Solver Performance Comparison (Parallel)"
echo "=================================================="
echo "Models directory: $MODELS_DIR"
echo "Output directory: $RUN_DIR"
echo "Timeout: ${TIMEOUT}s"
echo "Solvers: ${SOLVERS[*]}"
echo "Max parallel tasks: $MAX_PARALLEL"
echo "Found ${#MODEL_FILES[@]} model files"
echo ""

# Create summary info file
cat > "$RUN_DIR/run_info.txt" << EOF
MiniZinc Solver Performance Comparison
======================================
Start time: $(date)
Models directory: $MODELS_DIR
Output directory: $RUN_DIR
Timeout: ${TIMEOUT}s
Solvers: ${SOLVERS[*]}
Max parallel tasks: $MAX_PARALLEL
Total models: ${#MODEL_FILES[@]}

Model files:
EOF

for file in "${MODEL_FILES[@]}"; do
    echo "  - $(basename "$file")" >> "$RUN_DIR/run_info.txt"
done

echo "" >> "$RUN_DIR/run_info.txt"

# Function to run a single model with all solvers
run_model() {
    local model_file="$1"
    local model_name=$(basename "$model_file" .mzn)
    local log_file="$RUN_DIR/${model_name}.log"
    
    echo "[PARALLEL] Starting $model_name"
    
    # Call run.sh to process this model with all solvers
    bash "scripts/run.sh" \
        --model-file "$model_file" \
        --solvers cp-sat chuffed choco \
        --timeout "$TIMEOUT" \
        --output-file "$log_file"
    
    local status=$?
    if [ $status -eq 0 ]; then
        echo "[PARALLEL] Completed $model_name"
    else
        echo "[PARALLEL] Failed $model_name (exit code: $status)"
    fi
    
    return $status
}

# Export function and variables for parallel execution
export -f run_model
export RUN_DIR SOLVERS TIMEOUT

# Run models in parallel using GNU parallel or xargs
echo "Starting parallel execution..."
start_time=$(date +%s)

if command -v parallel >/dev/null 2>&1; then
    # Use GNU parallel if available
    printf '%s\n' "${MODEL_FILES[@]}" | parallel -j "$MAX_PARALLEL" run_model
else
    # Fallback to xargs with background processes
    printf '%s\n' "${MODEL_FILES[@]}" | xargs -n 1 -P "$MAX_PARALLEL" -I {} bash -c 'run_model "$@"' _ {}
fi

end_time=$(date +%s)
total_time=$((end_time - start_time))

echo ""
echo "All tests completed in ${total_time}s"

# Generate summary report
echo "Generating summary report..."
python3 - << EOF
import os
import re
import json
from pathlib import Path

run_dir = Path("$RUN_DIR")
solvers = ["${SOLVERS[0]}", "${SOLVERS[1]}", "${SOLVERS[2]}"]
results = {}
detailed_results = []

# Parse log files
for log_file in run_dir.glob("*.log"):
    model_name = log_file.stem
    results[model_name] = {}
    
    content = log_file.read_text(encoding='utf-8')
    
    # Parse each solver result
    for solver in solvers:
        solver_pattern = rf"SOLVER: {re.escape(solver)}.*?SOLVING_TIME: ([\d.]+).*?RESULT: (\w+)"
        match = re.search(solver_pattern, content, re.DOTALL)
        
        if match:
            solving_time = float(match.group(1))
            result_status = match.group(2)
            
            detailed_results.append({
                'model': model_name,
                'solver': solver,
                'status': result_status,
                'time': solving_time
            })
            
            if result_status == 'SUCCESS':
                results[model_name][solver] = solving_time
            else:
                results[model_name][solver] = float('inf')
        else:
            results[model_name][solver] = float('inf')
            detailed_results.append({
                'model': model_name,
                'solver': solver,
                'status': 'UNKNOWN',
                'time': None
            })

# Save detailed results
with open(run_dir / "detailed_results.json", 'w') as f:
    json.dump(detailed_results, f, indent=2)

# Generate summary report
with open(run_dir / "summary_report.txt", 'w') as f:
    f.write("MiniZinc Solver Performance Comparison Report\\n")
    f.write("=" * 50 + "\\n")
    f.write(f"Test completed: $(date)\\n")
    f.write(f"Total time: ${total_time}s\\n")
    f.write(f"Models tested: {len(results)}\\n")
    f.write(f"Solvers: {', '.join(solvers)}\\n\\n")
    
    # Performance table
    f.write("Performance Summary (seconds):\\n")
    f.write("-" * 40 + "\\n")
    f.write(f"{'Model':<20} {'cp-sat':<10} {'chuffed':<10} {'choco':<10}\\n")
    f.write("-" * 40 + "\\n")
    
    for model, solver_times in results.items():
        f.write(f"{model:<20} ")
        for solver in solvers:
            time_val = solver_times.get(solver, float('inf'))
            if time_val == float('inf'):
                f.write(f"{'FAIL':<10} ")
            else:
                f.write(f"{time_val:<10.3f} ")
        f.write("\\n")
    
    f.write("\\n")
    
    # Success rate
    f.write("Success Rate by Solver:\\n")
    f.write("-" * 25 + "\\n")
    for solver in solvers:
        total = len(results)
        success = sum(1 for model_results in results.values() 
                     if model_results.get(solver, float('inf')) != float('inf'))
        rate = (success / total * 100) if total > 0 else 0
        f.write(f"{solver:<15}: {success:2}/{total} ({rate:5.1f}%)\\n")

print("Summary report generated")
EOF

echo ""
echo "Results saved to: $RUN_DIR"
echo "  - Individual logs: *.log files"
echo "  - Detailed results: detailed_results.json"
echo "  - Summary report: summary_report.txt"
echo "  - Run info: run_info.txt"
