clear,clc;
n=9;
a=zeros(n,n);
a(1,2:9)=[2 1 3 4 4 2 5 4];
a(2,[3 9])=[4 1];
a(3,4)=1;
a(4,5)=1;
a(5,6)=5;
a(6,7)=2;
a(7,8)=3;
a(8,9)=5;
w=a+a';
w(w==0)=10000;
G=graph(w);
prob = optimproblem;
x = optimvar('x',n,n,'Type','integer','LowerBound',0,'UpperBound',1);
u = optimvar('u',n,'LowerBound',0); % 确保不成环
prob.Objective = sum(sum(w.*x));
con_x1 = sum(x(1,:))>=1; % 根至少有1条边流出
con_x2=optimconstr(n-1);
for j=2:1:n
    con_x2(j-1) = sum(x(:,j))==1; % 除根外，每个顶点只有1条边流入（否则会成环）
end
con_u1 = optimconstr(n*(n-1));
k=0;
for i = 1:n
    for j = 2:n
        k=k+1;
        con_u1(k) = u(i)-u(j)+n*x(i,j)<=n-1;
    end
end
con_u2 = optimconstr(n-1);
for i=2:1:n
    con_u2(i-1) = u(i)>=1;
end
con_u3 = optimconstr(n-1);
for i=2:1:n
    con_u3(i-1) = u(i)<=n-1;
end
prob.Constraints.con1 = con_x1;
prob.Constraints.con2 = con_x2;
prob.Constraints.con3 = u(1)==0;
prob.Constraints.con4 = con_u1;
prob.Constraints.con5 = con_u2;
prob.Constraints.con6 = con_u3;
[sol,fval,flag,out] = solve(prob);
X=sol.x;
X=X';
[i,j]=find(sol.x);
tree=[j';i'];