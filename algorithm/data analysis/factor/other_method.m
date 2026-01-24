r=[1 1/5 -1/5
   1/5 1 -2/5
  -1/5 -2/5 1];
% 主因子分析法:在主成分分析法的基础上，先对相关系数矩阵进行修正
n=size(r,1); % 提取行数
rt=abs(r);
for i=1:1:n
    for j=1:1:n
        if i==j
            rt(i,j)=0;
        end
    end
end
rstar=r;
for i=1:1:n
    for j=1:1:n
        if i==j
            rstar(i,j)=max(rt(i,:)); % rstar对角线为各变量与其他变量的最大绝对相关系数
        end
    end
end
[vec,val,rate]=pcacov(rstar);
vec1=vec*diag(sqrt(val));
aa=vec1(:,[1,2]);
ss=rstar-aa*aa';

% 最大似然估计法