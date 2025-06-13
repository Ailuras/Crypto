int: n_nodes = 5;
int: n_colors = 3;
array[1..n_nodes, 1..n_nodes] of int: edges = [|0,1,1,0,0|1,0,1,1,0|1,1,0,1,1|0,1,1,0,1|0,0,1,1,0|];
array[1..n_nodes] of var 1..n_colors: colors;
constraint forall(i in 1..n_nodes, j in 1..n_nodes where edges[i,j] = 1)(colors[i] != colors[j]);
solve satisfy;
output ["Node " ++ show(i) ++ " colored with color " ++ show(colors[i]) ++ "\n" | i in 1..n_nodes]; 