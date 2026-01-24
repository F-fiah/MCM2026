% Verhulst模型适合用于描述具有饱和状态的过程

x0=[4.93 2.33 3.87 4.35 6.63 7.15 5.37 6.39 7.81 8.35];
n=length(x0);
x1=cumsum(x0);
z=0.5*(x1(2:n)+x1(1:n-1));
x0=x0';
x1=x1';
z=z';

% 模型方程：x0(k) + a*z(k) = b*z(k)^2
B=[-z,z.^2];
u=B\x0(2:n);

syms x(t);
x = dsolve (diff(x) + u(1)*x == u(2)*x^2,x(0)==x0(1));  
xt=vpa(x,6); 

yuce=subs(x,t,0:n-1); 
yuce=double(yuce); 
x0_hat=[yuce(1),diff(yuce)]';
epsilon=x0-x0_hat;  
delta=abs(epsilon./x0); 