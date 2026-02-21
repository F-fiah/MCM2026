clc,clear, close all
a = readmatrix('anli10_1.txt'); 
a(:,[3:6])=[];
b=zscore(a);
z=linkage(b,'average');
h=dendrogram(z);
set(h,'Color','k','LineWidth',1.3)
    fprintf('划分成分%d类的结果如下\n',k)
    T=cluster(z,'maxclust',k);
    for i=1:k
      tm=find(T==i);
      fprintf('第%d类为%s\n',i,int2str(tm'));
end
