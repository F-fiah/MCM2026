syms x y;
syms z positive;
a=load('data15_11.txt'); 
d=a(:,2:end);
n=size(a,1); % 求矩阵的行数
answer=zeros(n,3);
for i=1:1:n
    eq1=x^2+y^2+z^2-d(i,1)^2;  
    eq2=x^2+(y-4500)^2+z^2-d(i,2)^2;
    eq3=(x+2000)^2+(y-1500)^2+z^2-d(i,3)^2;
    [X,Y,Z]=solve(eq1,eq2,eq3);
    answer(i,1)=X;
    answer(i,2)=Y;
    answer(i,3)=Z;
end