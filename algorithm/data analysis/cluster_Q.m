% 用距离来度量样本点之间的相似程度
% 计算距离时，变量的量纲要相同，所以要先对数据进行标准化处理

% pdist函数：进行样本间距离计算，Y=squareform(pdist(X,'metric'))，Yij为X的第i，j个行向量的距离
% linkage函数：根据样本间距离合并样本，通过类之间的距离构建层次聚类树

X=[1,0;1,1;3,2;4,3;2,5];
Y=pdist(X,'cityblock');
Z=linkage(Y, 'single'); % 构建聚类树，输出z为聚类过程的矩阵
                        % single：聚类方法为单链接法（最短距离法）
dendrogram(Z); % 根据linkage输出的聚类树z，绘制层次聚类树状图                                     
T1=cluster(Z,'maxclust',3); % 根据聚类树z，将样本强制划分为3类
                           % T为列向量，长度为样本数，其中每个元素的值表示对应样本的类别编号
T2=cluster(Z,'cutoff',2); % 指定距离阈值，两类合并的距离超过这个阈值时，就不再合并
                           
for i=1:1:3
    tm=find(T1==i); 
    fprintf('第%d类的有%s\n',i,int2str(tm')); 
end