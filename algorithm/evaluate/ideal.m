% 理想算法的核心：靠近正理想解且原理负理想解的发难为最优方案
% 在TOPSIS 算法中，处理混合类型多指标评价数据时，向量规范化是唯一正确的预处理选择（因为该算法需要计算欧氏距离）

a=[0.1	5	5000	4.7
 0.2	6	6000	5.6
 0.4	7	7000	6.7
 0.9	10	10000	2.3
 1.2	2	400	    1.8];
[m,n]=size(a);
% 第1,3列为效益型指标,指标值越大越好;第2列为效益型指标,指标值越小越好;

% a的第二列为区间型属性，要先进行属性变换
trans = @(qujian,lb,ub,x) (1-(qujian(1)-x)./(qujian(1)-lb)).*(x>=lb & x<qujian(1))...
+1.*(x>=qujian(1) & x<=qujian(2))...
+(1-(x-qujian(2))./(ub-qujian(2))).*(x>qujian(2) & x<=ub);
qujian=[5,6]; % 最优区间
lb=2; % 无法容忍下界
ub=12; % 无法容忍上界
x2=a(:,2);
y2=trans(qujian,lb,ub,x2);
a(:,2)=y2;

for i=1:1:n
    b(:,i)=a(:,i)/norm(a(:,i)); 
end  % 进行向量的规范化，其中vecnorm函数用于求解向量的范数

w=[0.2 0.3 0.4 0.1]; % 题目给出的权向量，若题目未给出，则通常用熵权法求解
c=b.*w; % 求解加权矩阵

% ！关键：求理想解
Cbest=max(c);   % 求c每一列的最大值，返回行向量
Cbest(4)=min(c(:,4)); % 修正Cideal的第四个值
Cleast=min(c);      
Cleast(4)=max(c(:,4)); 

for i=1:1:m
    Sbest(i)=norm(c(i,:)-Cbest); 
    Sleast(i)=norm(c(i,:)-Cleast);     
end
f=Sleast./(Sbest+Sleast); % f越大，则评价越优
[sf,ind]=sort(f,'descend'); % 对f进行降序排序，sf为排序后的数组，ind为原始对象下标