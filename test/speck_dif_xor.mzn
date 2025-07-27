include "globals.mzn";

int: n = 32;

predicate difModularAddition(array[int] of var 0..1: x, array[int] of var 0..1: y, array[int] of var 0..1: z, var int: pLog2) = 
    let {
      array[0..n-2] of var 0..1: neq;
      array[1..n-1] of var bool: bx;
      array[1..n-1] of var bool: by;
      array[1..n-1] of var bool: bz;
      array[1..n-1] of var bool: bx_prev;
      
      constraint forall(i in 0..n-2)(
        if x[i] == y[i] /\ y[i] == z[i] then
          neq[i] = 0
        else
          neq[i] = 1
        endif
      );
      
      constraint forall(i in 1..n-1)(
        bx[i] = (x[i] = 1) /\
        by[i] = (y[i] = 1) /\
        bz[i] = (z[i] = 1) /\
        bx_prev[i] = (x[i-1] = 1)
      );
    }
    in
      x[0]+y[0]+z[0] in {0,2} /\
      forall(i in 1..n-1)(
        if neq[i-1] == 0 then 
          not (bx[i] xor by[i] xor bz[i] xor bx_prev[i])
        endif
      ) /\
      pLog2 = sum(i in 0..n-2)(neq[i]);

predicate difRound(array[int] of var 0..1: leftInput, array[int] of var 0..1: rightInput,
                   array[int] of var 0..1: leftOutput, array[int] of var 0..1: rightOutput,
                   int: s, int: t, var int: pLog2) = 
    let {
      array[0..n-1] of var 0..1: modularAdditionUpInput;
      array[0..n-1] of var 0..1: xorUpInput;
      
      constraint forall(i in 0..n-1)(modularAdditionUpInput[i] = leftInput[(i+s) mod n]);
      constraint forall(i in 0..n-1)(xorUpInput[i] = rightInput[(i-t+n) mod n]);
    } 
    in
      difModularAddition(modularAdditionUpInput, rightInput, leftOutput, pLog2) /\
      forall(i in 0..n-1)(
        leftOutput[i] + xorUpInput[i] + rightOutput[i] in {0,2}
      );

int: rounds = 3;   % 差分轮数
int: alpha = 8;
int: beta = 3;

array[0..rounds, 0..1, 0..n-1] of var 0..1: vars;     % 每轮输入输出的 left/right
array[0..rounds-1] of var int: weights;               % 每轮差分活跃位数估计

constraint forall(i in 0..rounds-1)(
  difRound(vars[i,0,..], vars[i,1,..], vars[i+1,0,..], vars[i+1,1,..], alpha, beta, weights[i])
);

var int: total_weight = sum(i in 0..rounds-1)(weights[i]);

constraint (sum(i in 0..n-1)(vars[0,0,i] + vars[0,1,i])) > 0;   % 输入非零
constraint (sum(i in 0..n-1)(vars[rounds,0,i] + vars[rounds,1,i])) > 0;  % 输出非零

solve minimize total_weight;

output [
  "Round \(i): Left = \(vars[i,0,..]), Right = \(vars[i,1,..])\n" | i in 0..rounds
] ++ ["Total weight: \(total_weight)\n"];
