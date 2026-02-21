clc, clear, close all
a=readmatrix('anli10_1.txt');
b=zscore(a);
r=corrcoef(b);
%d=tril(1-r); d=nonzeros(d)';
z=linkage(b','average','correlation');
h=dendrogram(z);
set(h,'Color','k','LineWidth',1.3)
T=cluster(z,'maxclust',6)
for i=1:6
    tm=find(T==i);
    fprintf('第%d类为%s\n',i,int2str(tm'));
end