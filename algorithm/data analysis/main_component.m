% 选择适当的变量权重，使样本值尽可能分散（区分开）
% 运用方差来反映数据的差异程度，主成分中变量的方差应足够大
% 不同的主成分的协方差为0（互不相关），即主成分方向正交
% 选取主成分既要看累积贡献率，也要看主成分对原始变量的贡献值

data=[7	26	6	60	78.5
1	29	15	52	74.3
11	56	8	20	104.3
11	31	8	47	87.6
7	52	6	33	95.9
11	55	9	22	109.2
3	71	17	6	102.7
1	31	22	44	72.5
2	54	18	22	93.1
21	47	4	26	115.9
1	40	23	34	83.8
11	66	9	12	113.3
10	68	8	12	109.4];
[m,n]=size(data);
x0=data(:,1:4);
X=[x0,ones(m,1)];
y0=data(:,5);
k=X\y0;
fprintf('y=');
for i=1:1:n
    if i~=n
        fprintf('%fx%d+',k(i),i);
    else
        fprintf('%f\n',k(n));
    end
end
r=corrcoef(x0); % 自变量的相关系数矩阵
x1=zscore(x0);
y1=zscore(y0);
[vec,lamda,rate]=pcacov(r); % 只提取出来了主成分，还要计算每个主成分的系数
contribute=cumsum(rate);
num=3;
vec1=vec(:,[1:num]);
f=x1*vec1;
F=[f,ones(m,1)];
b=F\y1;

% 把标准化空间的主成分回归系数，还原为原始数据空间的系数
mu_x0 = mean(x0);
sigma_x0 = std(x0,1); % 计算x0每一列的样本标准差
mu_y0 = mean(y0);
sigma_y0 = std(y0,1);
beta_std = vec1 * b(1:num);
beta = sigma_y0 * beta_std ./ (sigma_x0)'; 
beta0 = mu_y0 - sigma_y0 * (mu_x0 ./ sigma_x0) * beta_std;
k_pcr = [beta; beta0];
fprintf('y=');
for i=1:1:n
    if i~=n
        fprintf('%fx%d+',k_pcr(i),i);
    else
        fprintf('%f\n',k_pcr(i));
    end
end
% 计算各自的均方根误差
RSME1 = sqrt(sum((x0*k(1:4,1)+k(5,1)-y0).^2)/(m-5));
RSME2 = sqrt(sum((x0*k_pcr(1:4,1)+k_pcr(5,1)-y0).^2)/(m-num-1));
disp(RSME1);
disp(RSME2);