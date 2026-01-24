% Dijkstra算法值适用于解决单源单汇、非负权、无附加约束的最短路径
% 对于带复杂约束（如节点容量、边数限制）、多目标、多源多汇、路径数限制的最大路径问题，则可以采用0-1 整数规划

clear,clc;
a = zeros(6);
a(1,[2,5])=[18,15];
a(2,[3:5])=[20,60,12];
a(3,[4,5])=[30,18];
a(4,6)=10;
a(5,6)=15;
w = a+a';
w(w==0)=1000;
prob = optimproblem;
x = optimvar('x',6,6,'Type','integer','LowerBound',0,'UpperBound',1);
prob.Objective = sum(sum(w.*x));
con1 = optimconstr(4);
con1(1) = sum(x(1,:))==sum(x(:,1));
con1(2) = sum(x(3,:))==sum(x(:,3));
con1(3) = sum(x(5,:))==sum(x(:,5));
con1(4) = sum(x(6,:))==sum(x(:,6)); % 出起点和终点外，其余各点的流入=流出
prob.Constraints.con1 = con1;
prob.Constraints.con2 = [sum(x(2,:))==1; sum(x(:,2))==0; sum(x(:,4))==1; sum(x(4,:))==0]; % 起点，终点的流入和流出
[sol,fval,flag,out]= solve(prob);
X=sol.x;
X=X';
[i,j] = find(X); % 按“列优先”的顺序，找所有非零元素的行索引和列索引，i、j均为列向量