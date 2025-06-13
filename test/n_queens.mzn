include "alldifferent.mzn";
int: n = 8;
array[1..n] of var 1..n: queens;
constraint alldifferent(queens);
constraint alldifferent([queens[i] + i | i in 1..n]);
constraint alldifferent([queens[i] - i | i in 1..n]);
solve satisfy;
output [show(queens[i]) ++ if i == n then "\n" else " " endif | i in 1..n]; 