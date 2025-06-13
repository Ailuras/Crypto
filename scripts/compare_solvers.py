#!/usr/bin/env python3
import subprocess
import time
import pandas as pd
import argparse
import json
import os
import sys
from pathlib import Path
from typing import List, Dict, Optional

class SolverComparator:
    def __init__(self, models_dir: str = "benchmarks/CP", 
                 solvers: List[str] = None, 
                 timeout: int = 1200,
                 output_dir: str = "results",
                 use_emoji: bool = None):
        self.models_dir = Path(models_dir)
        self.solvers = solvers or self._get_available_solvers()
        self.timeout = timeout
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(exist_ok=True)
        
        # 自动检测是否支持emoji（基于操作系统和终端）
        if use_emoji is None:
            self.use_emoji = self._detect_emoji_support()
        else:
            self.use_emoji = use_emoji
        
        # 存储结果
        self.results = {}
        self.detailed_results = []
    
    def _detect_emoji_support(self) -> bool:
        """检测终端是否支持emoji"""
        # 在Linux服务器环境中通常禁用emoji
        if os.getenv('SSH_CONNECTION') or os.getenv('SSH_CLIENT'):
            return False
        
        # 检查TERM环境变量
        term = os.getenv('TERM', '').lower()
        if any(x in term for x in ['screen', 'tmux', 'linux']):
            return False
            
        # macOS通常支持emoji
        if sys.platform == 'darwin':
            return True
            
        return False
    
    def _get_status_icon(self, status: str) -> str:
        """根据状态返回图标或文本"""
        if self.use_emoji:
            icons = {
                'success': '✅',
                'failed': '❌', 
                'timeout': '⏰',
                'error': '💥',
                'testing': '🔧',
                'results': '📊',
                'summary': '📈'
            }
        else:
            icons = {
                'success': '[OK]',
                'failed': '[FAIL]',
                'timeout': '[TIMEOUT]',
                'error': '[ERROR]',
                'testing': '[TEST]',
                'results': '[RESULTS]',
                'summary': '[SUMMARY]'
            }
        return icons.get(status, '[?]')
    
    def _get_available_solvers(self) -> List[str]:
        """自动检测可用的求解器"""
        try:
            result = subprocess.run(['minizinc', '--solvers'], 
                                  capture_output=True, text=True)
            if result.returncode == 0:
                # 从输出中提取求解器名称
                available = []
                for line in result.stdout.split('\n'):
                    if '(' in line and ')' in line:
                        # 提取括号中的标识符
                        parts = line.split('(')[1].split(')')[0].split(',')
                        if parts:
                            solver_id = parts[0].strip()
                            # 只添加常见的求解器标识符
                            if any(keyword in solver_id.lower() for keyword in 
                                  ['gecode', 'chuffed', 'coin-bc', 'cp-sat', 'cbc']):
                                available.append(solver_id)
                
                # 如果没有找到，使用默认的可用求解器
                if not available:
                    available = ['coin-bc', 'cp-sat']
                
                return available
        except Exception:
            pass
        
        # 默认求解器
        return ['coin-bc', 'cp-sat']
    
    def _find_model_files(self) -> List[Path]:
        """自动发现模型文件"""
        model_files = []
        
        if not self.models_dir.exists():
            print(f"[ERROR] Models directory not found: {self.models_dir}")
            return []
        
        # 递归查找所有.mzn文件
        for mzn_file in self.models_dir.rglob("*.mzn"):
            model_files.append(mzn_file)
        
        return sorted(model_files)
    
    def _run_solver(self, model_file: Path, solver: str) -> Dict:
        """运行单个求解器测试"""
        print(f"  Testing {solver}...", end=" ", flush=True)
        
        start_time = time.time()
        result_info = {
            'model': model_file.name,
            'model_path': str(model_file),
            'solver': solver,
            'status': 'unknown',
            'time': None,
            'error': None
        }
        
        try:
            # 构建命令
            cmd = ['minizinc', '--solver', solver, str(model_file)]
            
            # 运行命令
            result = subprocess.run(cmd, 
                                  capture_output=True, 
                                  text=True, 
                                  timeout=self.timeout)
            
            solve_time = time.time() - start_time
            result_info['time'] = solve_time
            
            if result.returncode == 0:
                result_info['status'] = 'success'
                print(f"{self._get_status_icon('success')} {solve_time:.2f}s")
            else:
                result_info['status'] = 'failed'
                result_info['error'] = result.stderr[:200] if result.stderr else "Unknown error"
                print(f"{self._get_status_icon('failed')} Failed")
                
        except subprocess.TimeoutExpired:
            result_info['status'] = 'timeout'
            result_info['time'] = self.timeout
            print(f"{self._get_status_icon('timeout')} Timeout ({self.timeout}s)")
            
        except Exception as e:
            result_info['status'] = 'error'
            result_info['error'] = str(e)
            print(f"{self._get_status_icon('error')} Error: {str(e)[:50]}...")
        
        return result_info
    
    def run_comparison(self):
        """运行完整的求解器比较"""
        print("MiniZinc Solver Performance Comparison")
        print("=" * 50)
        print(f"Models directory: {self.models_dir}")
        print(f"Timeout: {self.timeout}s")
        print(f"Solvers: {', '.join(self.solvers)}")
        print(f"Platform: {sys.platform}")
        print()
        
        # 发现模型文件
        model_files = self._find_model_files()
        if not model_files:
            print("[ERROR] No .mzn files found!")
            return
        
        print(f"Found {len(model_files)} model files:")
        for mf in model_files:
            print(f"  - {mf.relative_to(self.models_dir)}")
        print()
        
        # 运行测试
        for model_file in model_files:
            model_name = model_file.stem
            print(f"{self._get_status_icon('testing')} Testing {model_name} ({model_file.relative_to(self.models_dir)}):")
            
            self.results[model_name] = {}
            
            for solver in self.solvers:
                result_info = self._run_solver(model_file, solver)
                self.detailed_results.append(result_info)
                
                # 存储简化结果用于表格
                if result_info['status'] == 'success':
                    self.results[model_name][solver] = result_info['time']
                else:
                    self.results[model_name][solver] = float('inf')
            
            print()
    
    def save_results(self):
        """保存结果到文件"""
        # 保存详细结果为JSON
        detailed_file = self.output_dir / "detailed_results.json"
        with open(detailed_file, 'w') as f:
            json.dump(self.detailed_results, f, indent=2)
        
        # 保存汇总表格为CSV
        if self.results:
            df = pd.DataFrame(self.results).T
            df = df.fillna(float('inf'))  # 填充缺失值
            
            summary_file = self.output_dir / "solver_comparison.csv"
            df.to_csv(summary_file)
            
            print(f"{self._get_status_icon('results')} Results saved:")
            print(f"  - Detailed: {detailed_file}")
            print(f"  - Summary: {summary_file}")
            
            return df
        
        return None
    
    def print_summary(self):
        """打印结果摘要"""
        if not self.results:
            print("No results to display.")
            return
        
        df = pd.DataFrame(self.results).T
        df = df.fillna(float('inf'))
        
        print(f"\n{self._get_status_icon('summary')} Performance Summary (seconds):")
        print("=" * 50)
        
        # 替换inf为更友好的显示
        display_df = df.copy()
        display_df = display_df.replace(float('inf'), 'FAIL/TIMEOUT')
        print(display_df.to_string())
        
        # 统计成功率
        print(f"\n{self._get_status_icon('results')} Success Rate by Solver:")
        print("-" * 30)
        for solver in self.solvers:
            if solver in df.columns:
                total = len(df)
                success = sum(df[solver] != float('inf'))
                rate = (success / total * 100) if total > 0 else 0
                print(f"{solver:15}: {success:2}/{total} ({rate:5.1f}%)")

def main():
    parser = argparse.ArgumentParser(description='Compare MiniZinc solver performance')
    parser.add_argument('--models-dir', default='benchmarks/CP',
                       help='Directory containing model files (default: benchmarks/CP)')
    parser.add_argument('--solvers', nargs='+',
                       help='Solvers to test (default: auto-detect)')
    parser.add_argument('--timeout', type=int, default=300,
                       help='Timeout in seconds (default: 300)')
    parser.add_argument('--output-dir', default='results',
                       help='Output directory for results (default: results)')
    parser.add_argument('--no-emoji', action='store_true',
                       help='Disable emoji icons (for better Linux compatibility)')
    
    args = parser.parse_args()
    
    # 创建比较器
    comparator = SolverComparator(
        models_dir=args.models_dir,
        solvers=args.solvers,
        timeout=args.timeout,
        output_dir=args.output_dir,
        use_emoji=not args.no_emoji
    )
    
    # 运行比较
    comparator.run_comparison()
    
    # 保存和显示结果
    comparator.save_results()
    comparator.print_summary()

if __name__ == "__main__":
    main()

# # 生成简单的性能比较图表
# import matplotlib.pyplot as plt

# plt.figure(figsize=(12, 6))
# df.plot(kind='bar')
# plt.title('Solver Performance Comparison')
# plt.xlabel('Models')
# plt.ylabel('Solving Time (seconds)')
# plt.xticks(rotation=45)
# plt.tight_layout()
# plt.savefig('solver_comparison.png')