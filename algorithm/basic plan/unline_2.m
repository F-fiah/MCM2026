% 二次规划问题：目标函数是二次型 + 线性项，约束是线性（不）等式约束
% 解法1：optimproblem + solve
% 解法2：fmincon（非线性规划求解器）求解

% 法1
prob=optimproblem;
x = optimvar('x',2,1, 'LowerBound',zeros(2,1));
H=[-1,-0.15;
   -0.15,-2]; % 二次项矩阵
f=[98;277];   % 线性项向量
A=[1,1;
   1,-2];     % 约束矩阵
b=[100;0];    % 约束右端向量
prob.Objective = x'*H*x+f'*x;
prob.Constraints = A*x <= b;
[sol,fval,exitflag,output] = solve(prob);

% 法2 fmincon(目标函数, 初始值, 不等式约束矩阵A, 不等式约束向量b, 等式约束矩阵Aeq, 等式约束向量beq, 下界, 上界)
fx = @(x) x'*H*x+f'*x;
[x,y] = fmincon(fx,rand(2,1),A,b,[],[],zeros(2,1),Inf*ones(2,1));

% fmincon函数默认计算最小值，若要计算最大值，则将函数取负