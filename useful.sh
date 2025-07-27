minizinc -c --solver CP-SAT --output-fzn-to-file speck.fzn benchmarks/CP/speck/Speck.

time minizinc --solver CP-SAT speck_dif.mzn
time minizinc --solver CP-SAT speck_dif_and.mzn
time minizinc --solver CP-SAT speck_dif_mod.mzn
time minizinc --solver CP-SAT speck_dif_xor.mzn