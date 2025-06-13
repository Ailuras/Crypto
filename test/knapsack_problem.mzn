int: n;
int: capacity;
array[1..n] of int: weights;
array[1..n] of int: values;
array[1..n] of var 0..1: x;
constraint sum(i in 1..n)(weights[i] * x[i]) <= capacity;
solve maximize sum(i in 1..n)(values[i] * x[i]);
output ["Selected items: "] ++ [show(i) ++ " " | i in 1..n where fix(x[i]) == 1] ++ ["\nTotal value: "] ++ [show(sum(i in 1..n)(values[i] * x[i]))] ++ ["\nTotal weight: "] ++ [show(sum(i in 1..n)(weights[i] * x[i]))]; 