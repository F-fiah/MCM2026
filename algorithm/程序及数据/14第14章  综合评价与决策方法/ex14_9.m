clc, clear
a=readmatrix('data14_9_1.txt');
[n,m]=size(a);
for j=1:m
    p(:,j)=a(:,j)/sum(a(:,j));
    e(j)=-sum(p(:,j).*log(p(:,j)))/log(n);
end
g=1-e; w=g/sum(g) 
s=w*p' 
[ss,ind1]=sort(s,'descend') 
ind2(ind1)=1:n  
writematrix(w,'data14_9_2.xlsx') 
writematrix([1:n;s;ind2],'data14_9_2.xlsx','Sheet',2) 

