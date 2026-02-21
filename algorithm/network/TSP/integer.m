data=importdata('data_integer.xlsx');
data(isnan(data))=0;
n=15;
w=zeros(n,n);
for i=1:1:n-1
    for j=1:1:n-1
        if i~=j
            w(i,j) = sum(data(:,i).*data(:,j));
        end
    end
end
prob=optimproblem('ObjectiveSense','min');
x=optimvar('x',n,n,'Type','integer','LowerBound',0,'UpperBound',1); % xij=1表示最短路中有从i到j的路径
u=optimvar('u',n,'LowerBound',0);  %序号变量
prob.Objective = sum(sum(w.*x));
con_eq = [(sum(x,1)==1)';
          sum(x,2)==1;
          u(1)==0];
prob.Constraints.con1 = con_eq;
con_u = [1<=u(2:end);
         u(2:end)<=n-1];
prob.Constraints.con2 = con_u;
con3 = optimconstr(n*(n-1));
k=0;
for i=1:1:n
    for j=2:1:n
        k=k+1;
        con3(k) = u(i)-u(j)+n*x(i,j)<=n-1;
    end
end
prob.Constraints.con3 = con3;
[sol, fval, flag]=solve(prob);
[i,j] = find(sol.x);  % 提取x(i,j)=1的弧
path = 1; current = 1;
for k=2:1:n
    current = j(find(i==current));
    path=[path,current]; 
end
fprintf('最优总代价：%.2f\n',fval);
fprintf('TSP遍历路径：%s\n',num2str(path));