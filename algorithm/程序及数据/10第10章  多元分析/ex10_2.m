clc, clear, close all
a=readmatrix('data10_2.txt');  a(isnan(a))=0;   
d=1-abs(a); 
d=tril(d); 
b=nonzeros(d);
b=b';  
z=linkage(b,'complete');
y=cluster(z,'maxclust',2)   
ind1=find(y==1);ind1=ind1' 
ind2=find(y==2);ind2=ind2' 
h=dendrogram(z); 