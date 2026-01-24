function [th,err,yi] =polyfits(x,y,N,xi,r)
% x,y : 数据点，待拟合的变量
% N : 多项式拟合次数
% r : 加权系数的逆矩阵
% th : 多项式的降幂系数
% err ：拟合的相对误差
% xi,yi ：需要预测的新自变量和预测值

M=length(x);
x=x(:);y=y(:); % 转成列向量

% 判断调用函数的格式，适配不同输入参数
if nargin==4  % 输入参数为4个的情况
    % 情况1：用户输入的是(x,y,N,r)（第4个参数是r）
    if length(xi)==M  
        r=xi;  
        xi=x;  
    % 情况2：用户输入的是(x,y,N,xi)（第4个参数是xi）
    else r=1;  
    end
elseif nargin==3  % 输入参数为3个的情况（x,y,N）
    xi=x;  % 默认用原x作为预测点
    r=1;   % 默认权重为1（普通拟合）
end

% 求解系数矩阵：构造N次多项式的设计矩阵
A(:,N+1)=ones(M,1); 
for n=N:-1:1
    A(:,n)=A(:,n+1).*x;
end

% 加权拟合
if length(r)==M
    for m=1:M
        A(m,:)=A(m,:)/r(m);  % 第m行矩阵除以r(m)
        y(m)=y(m)/r(m);      % 第m个y值除以r(m)
    end
end

% 计算拟合系数
th=(A\y)';

% 计算拟合值与相对误差
ye=polyval(th,x);
err=norm(y-ye)/norm(y);

% 计算xi处的预测值
yi=polyval(th,xi);