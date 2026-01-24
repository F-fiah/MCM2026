% DGM(2,1)：简化版GM(2,1)模型

x0=[2.874,3.278,3.39,3.679,3.77,3.8]; 
n=length(x0); 
x1=cumsum(x0); % 计算累加序列
x2=diff(x0); % 计算差分序列
x0=x0';
x1=x1';
x2=x2';

% 模型方程：x2(k) + a*x0(k) = b
B=[-1*x0(2:n),ones(n-1,1)];
u=B\x2; % u=[a,b]

syms x(t);
d2x=diff(x,2); dx=diff(x);
x=dsolve(diff(x,2) + u(1).*diff(x) == u(2),x(0)==x0(1),dx(0)==x0(1));
                                          % 初值条件的选取完全由微分方程的阶数、模型的物理意义和拟合目标决定
                                          % 通常是1个原函数初值 + 1个一阶导数初值，或2个不同时刻的原函数初值
                                          % 前者适用于单调陡增、数值跨度大、规律性强的序列，抗数据波动能力强
                                          % 后者适用于缓慢增长、数值跨度小、增速持续变化的平稳序列，局部拟合精度高
xt=vpa(x,6); 
yuce=subs(x,t,0:n-1); 
yuce=double(yuce);
x0_hat=[yuce(1),diff(yuce)]; 
epsilon=x0-x0_hat;
delta=abs(epsilon./x0);