# MiniZinc Solver Comparison Tool

A tool for comparing MiniZinc solver performance.

## Quick Start

### Test solvers installation
```bash
./scripts/test_solvers.sh
```

### Run comparison (local)
```bash
python3 scripts/compare_solvers.py --timeout 300
```

### Run comparison (background)
```bash
# Using tmux (recommended)
./scripts/run_background.sh --tmux --timeout 3600

# Using nohup
./scripts/run_background.sh --timeout 3600
```

### Parallel execution
```bash
bash scripts/parallel.sh --models-dir benchmarks/CP --timeout 1200 --max-parallel 5
```

## Key Features

- Auto-detects available solvers and model files
- Cross-platform support (macOS/Linux)
- Background execution with tmux/nohup
- Parallel processing support
- Automatic emoji detection for Linux servers
- Detailed CSV and JSON results

## Output Files

```
results/
├── detailed_results.json
├── solver_comparison.csv

logs/
└── comparison_*.log
```

## Common Options

- `--timeout <seconds>`: Set solver timeout
- `--models-dir <path>`: Specify models directory
- `--solvers <list>`: Specify solvers to test
- `--no-emoji`: Disable emoji output
- `--max-parallel <n>`: Set parallel processes (parallel.sh only)