clc,clear
a=readmatrix('data10_5.txt'); [m,n]=size(a);
x0=a(:,[1:n-1]); y0=a(:,n); 
hg1=[ones(m,1),x0]\y0;
fprintf('y=%f',hg1(1));
for i=2:n
    if hg1(i)>0  
       fprintf('+%f*x%d',hg1(i),i-1);
    else
       fprintf('%f*x%d',hg1(i),i-1)
    end
end
fprintf('\n')  
r=corrcoef(x0)
xd=zscore(x0); 
yd=zscore(y0); 
[vec1,lamda,rate]=pcacov(r)
f=repmat(sign(sum(vec1)),size(vec1,1),1); 
vec2=vec1.*f 
contr=cumsum(rate) 
df=xd*vec2;  
num=input('��ѡ�����ɷֵĸ���:')  
hg21=df(:,[1:num])\yd  
hg22=vec2(:,1:num)*hg21  
hg23=[mean(y0)-std(y0)*mean(x0)./std(x0)*hg22, std(y0)*hg22'./std(x0)] 
fprintf('y=%f',hg23(1));
for i=2:n
    if hg23(i)>0
        fprintf('+%f*x%d',hg23(i),i-1);
    else
        fprintf('%f*x%d',hg23(i),i-1);
    end
end
fprintf('\n')
rmse1=sqrt(sum((hg1(1)+x0*hg1(2:end)'-y0).^2)/(m-n))   
rmse2=sqrt(sum((hg23(1)+x0*hg23(2:end)'-y0).^2)/(m-num)) 