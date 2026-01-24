clc,clear
x0=[2.874,3.278,3.39,3.679,3.77,3.8]; 
n=length(x0);
a_x0=diff(x0)';  
B=[-x0(2:end)',ones(n-1,1)]; 
u=B\a_x0  
syms x(t)
d2x=diff(x,2); dx=diff(x);
x=dsolve(d2x+u(1)*dx==u(2),x(0)==x0(1),dx(0)==x0(1));  
xt=vpa(x,6) 
yuce=subs(x,t,0:n-1); 
yuce=double(yuce) 
x0_hat=[yuce(1),diff(yuce)] 
epsilon=x0-x0_hat 
delta=abs(epsilon./x0) 