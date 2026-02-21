clc,clear
x0=[4.93   2.33   3.87   4.35   6.63   7.15   5.37   6.39   7.81   8.35];
x1=cumsum(x0);  
n=length(x0);
z=0.5*(x1(2:n)+x1(1:n-1));   
B=[-z',z'.^2];
Y=x0(2:end)';
u=B\Y;     
syms x(t)
x=dsolve(diff(x)+u(1)*x==u(2)*x^2,x(0)==x0(1));  
xt=vpa(x,6) 
yuce=subs(x,t,[0:n-1]); 
yuce=double(yuce) 
x0_hat=[yuce(1),diff(yuce)]
epsilon=x0-x0_hat  
delta=abs(epsilon./x0)  
writematrix([x0',x0_hat',epsilon',delta'], 'data155.xlsx')

