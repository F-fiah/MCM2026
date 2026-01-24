% 对于目标函数多个的问题（如让收益最大化的同时使风险最小化）
% 1、固定风险水平，优化收益
% 2、固定收益水平，优化风险
% 3、分风险和收益分布赋予权重，将目标函数化为一个

% 记风险度为a，计算不同风险度下的最大收益
clc, clear;
prob = optimproblem('ObjectiveSense','max');
x1 = optimvar('x1',5,1,'LowerBound',zeros(5,1));
earn=[0.05,0.27,0.19,0.185,0.185];
Aeq=[1,1.01,1.02,1.045,1.065];
M=10000;
prob.Objective=earn*x1;
prob.Constraints.con1= Aeq*x1==M;
risk=[0,0.025,0.015,0.055,0.026]';
for a=0:0.001:0.05
    prob.Constraints.con2= risk.*x1<=a*M;
    [sol,Q,flag,out]= solve(prob);
    subplot(3,1,1);
    hold on;
    plot(a,earn*sol.x1,'o');
end

% 记投资偏好系数为w，即风险的权重为w，收益的权重为1-w
x2=optimvar('x2',6,1,'LowerBound',zeros(6,1));
prob2 = optimproblem('ObjectiveSense','max');
prob2.Constraints.con1= Aeq*x2(1:5,1)==M;
prob2.Constraints.con2= risk.*x2(1:5,1)<=x2(6,1);
for w=0:0.05:1
    prob2.Objective=(1-w)*(earn*x2(1:5,1))-w*x2(6,1);
    [sol2,Q2,flag2,out2]= solve(prob2);
    subplot(3,1,2);
    hold on;
    plot(sol2.x2(6,1),earn*sol2.x2(1:5,1),'*');
    subplot(3,1,3);
    hold on;
    plot(w,sol2.x2(6,1),'o',w,earn*sol2.x2(1:5,1),'*');
end