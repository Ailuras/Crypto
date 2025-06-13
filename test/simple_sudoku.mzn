include "alldifferent.mzn";
int: n = 3;
int: n2 = n * n;
array[1..n2, 1..n2] of var 1..n2: grid;
constraint forall(i in 1..n2)(alldifferent([grid[i,j] | j in 1..n2]));
constraint forall(j in 1..n2)(alldifferent([grid[i,j] | i in 1..n2]));
constraint forall(i in 0..n-1, j in 0..n-1)(
    alldifferent([grid[r,c] | r in 1..n, c in 1..n where r > i*n /\ r <= (i+1)*n /\ c > j*n /\ c <= (j+1)*n])
);
solve satisfy;
output [show(grid[i,j]) ++ if j == n2 then "\n" else " " endif | i in 1..n2, j in 1..n2]; 