clear;clc;
data=[6	 2	6	7	4	2	5	9	60
      4	 9	5	3	8	5	8	2	55
      5	 2	1	9	7	4	3	3	51
      7	 6	7	3	9	2	7	1	43
      2	 3	9	5	7	2	6	5	41
      5	 5	2	2	8	1	4	3	52
      35 37	22	32	41	32	43	38  NaN];
price=data(1:end-1,1:end-1);
need=data(end,1:end-1);
produce=data(1:end-1,end);
prob=optimproblem; % 默认使目标函数最小化，最大化：prob = optimproblem('ObjectiveSense','max')
x=optimvar('x',6,8,'LowerBound',zeros(6,8)); % 优化变量
prob.Objective=sum(price.*x,'all');
prob.Constraints.con1 = sum(x,1) == need; % 对列求和
prob.Constraints.con2 = sum(x,2)<= produce; % 对行求和
[sol,fval,flag,out]=solve(prob);