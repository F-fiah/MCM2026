% 核心：x = optimvar('x',m,n,'Type','integer','LowerBound',0,'UpperBound',1);
clear,clc;
data=[9.4888	8.7928	11.5960	11.5643	5.6756	9.8497	9.1756	13.1385	15.4663	15.5464
5.6817	10.3868	3.9294	4.4325	9.9658	17.6632	6.1517	11.8569	8.8721	15.5868];
[m,n]=size(data);
distance=zeros(n,n);
for i=1:1:n
    for j=1:1:n
        if j<i
            distance(i,j)=distance(j,i);
        elseif j==i
            distance(i,j)=0;
        else
            distance(i,j)=sqrt((data(1,i)-data(1,j))^2+(data(2,i)-data(2,j))^2);
        end
    end
end
prob = optimproblem;
x = optimvar('x',n,'Type','integer','LowerBound',0,'UpperBound',1);
y = optimvar('y',n,n,'Type','integer','LowerBound',0,'UpperBound',1);
prob.Objective = sum(x);
con_d=optimconstr(n^2);
con_xy=optimconstr(n^2);
con_xx=optimconstr(n);
for i=1:1:n
    for j=1:1:n
        con_d(n*(i-1)+j) = distance(i,j)*y(i,j)<=10;
        con_xy(n*(i-1)+j) = x(i)>=y(i,j);
    end
end
for i=1:1:n
    con_xx(i) = x(i)==y(i,i);
end
prob.Constraints.con1 = sum(y,1)>=1;
prob.Constraints.con2 = sum(y,2)<=5;
prob.Constraints.con3 = con_d;
prob.Constraints.con4 = con_xx;
prob.Constraints.con5 = con_xy;
[sol, fval, flag] = solve(prob,'Solver','intlinprog');