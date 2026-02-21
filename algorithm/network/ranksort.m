data = importdata('data2_10.xlsx');
data(isnan(data))=0;
w=ones(14,14)*10^6;
for i=1:14
    for j=1:14
        if i~=j
            w(i,j)=sum(data(:,i).*data(:,j));
        end
    end
end

prob=optimproblem;
n=15;
w(n,n)=10^6;
x=optimvar('x',n,n,'Type','integer','LowerBound',0,'UpperBound',1);
u=optimvar('u',n,'LowerBound',0);
prob.Objective=sum(sum(w.*x));
prob.Constraints.con1 = [sum(x,2)==1; sum(x,1)'==1; u(1)==0];
con2 = optimconstr(n*(n-1));
k=0;
for i=1:n
    for j=2:n
        k=k+1;
        con2(k)=u(i)-u(j)+n*x(i,j)<=n-1;
    end
end
prob.Constraints.con2 = con2;
con_u = optimconstr(2*n);
for i=1:1:n
    con_u(i) = 1<=u(i);
    con_u(n+i) = u(i)<=n-1;
end
prob.Constraints.con3 = con_u;
[sol, fval, flag]=solve(prob);