% GM2_1模型用于原始序列有明显二阶趋势时（快速递增，且增速先快后缓）

x0=[41,49,61,78,96,104];
n=length(x0); 
x1=cumsum(x0); % 计算累加序列
x2=diff(x0); % 计算差分序列，x2应该要有明显上升/下降/波动趋势
z=0.5.*x1(2:n) + 0.5.*x1(1:n-1); 
x0=x0';
x1=x1';
x2=x2';
z=z';

% 构建模型方程：x2(k) + a1*x0(k) + a2*z(k) = b
B=[-1.*x0(2:n),-1.*z,ones(n-1,1)];
u=B\x2; % 求解线性方程组 B*u=x2的最优解,其中u=[a1,a2,b]'

% 构建并求解白化微分方程
syms x(t);
x=dsolve (diff(x,2) + u(1).*diff(x) + u(2).*x==u(3),x(0)==x1(1),x(5)==x1(6));
xt=vpa(x,6); % 可选 求解得到的符号解析解x(t)，化简为保留 6 位有效数字的数值型符号表达式
yuce=subs(x,t,0:n-1);
yuce=double(yuce);
x0_hat=[yuce(1),diff(yuce)];
epsilon=x0-x0_hat;   
delta=abs(epsilon./x0); % 运用残差进行误差检验