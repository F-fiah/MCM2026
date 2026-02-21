data=readmatrix('data_cluster.txt');
% 先对变量进行R型聚类，选出代表性的指标后，再用这些指标进行Q型聚类
b=zscore(data); % 数据标准化
r=corrcoef(b); % 计算相关系数矩阵
n=size(r,1);
d=1-abs(r);
b=zeros(1,n*(n-1)/2);
k=0;
for i=1:1:n
    for j=i+1:1:n
        k=k+1;
        b(1,k)=d(i,j);
    end
end
z=linkage(b,'average');
subplot(1,2,1);
h=dendrogram(z);
T1=cluster(z,'maxclust',6);
% 从6个类中各选1个代表性变量，即选每类中与类内其他变量平均相似度最高（平均距离最小）的变量
% 由图可得，选2、3、7、8、9、10这6个变量最合适

a=data(:,[1,2,7,8,9,10]);
c=zscore(a);
Y=pdist(c,'seuclidean');
Z=linkage(Y,'average');
subplot(1,2,2);
H=dendrogram(Z);