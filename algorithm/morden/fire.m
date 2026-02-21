% 图与网络的精确算法，只适用于n<50的小规模 TSP 问题
% 对于n较大的问题，则需要使用退火算法

data=load('data.txt');
longitude_matrix=data(:,1:2:7);
longitude=longitude_matrix(:);
latitude_matrix=data(:,2:2:8);
latitude=latitude_matrix(:);
location=[longitude,latitude];
start=[70,40];
XY=[start;location;start];
xy=XY*pi/180;
n=size(location,1);
d=zeros(102,102);
for i=1:1:102
    for j=1:1:102
        if j<i
            d(i,j)=d(j,i);
        elseif i~=j
            d(i,j)=6370*acos(cos(xy(i,1)-xy(j,1))*cos(xy(i,2))*cos(xy(j,2))+sin(xy(i,2))*sin(xy(j,2)));
        end
    end
end
path=[]; % 最优路径向量
length=inf; % 最优路径总长度（初始设为无穷大）

% 生成模拟退火的初始较优路径
for j=1:1000  % 迭代1000次随机搜索
    path0=[1,1+randperm(100),102];  % 生成随机路径：randperm(n)：生成1~n的随机排列
    length0=0;
    for i=1:1:101
        length0=length0+d(path0(i),path0(i+1));  % 计算当前随机路径的总长度
    end
    if length0<length  % 保留更优路径
        path=path0; length=length0;
    end
end

% 模拟退火算法参数初始化
e=0.1^30;       % 终止温度，温度低于此值时停止迭代
L=20000;        % 最大迭代次数
at=0.999;       % 温度衰减系数（每次迭代温度乘以at，缓慢降温）
T=1;            % 初始温度

for k=1:1:L
    % 随机选择2个待交换的中间点
    c=randi([2,101],1,2);
    c=sort(c);
    c1=c(1);
    c2=c(2);

    % 反转两点之间的路段并消除路径交叉
    dlength = d(path(c1-1),path(c2))+d(path(c1),path(c2+1))-d(path(c1-1),path(c1))-d(path(c2),path(c2+1));

    if dlength<0
        path=[path(1:c1-1),path(c2:-1:c1),path(c2+1:102)];
        length=length+dlength;
    elseif exp(-dlength/T)>=rand % 若路径更长，则按概率接受
        path=[path(1:c1-1),path(c2:-1:c1),path(c2+1:102)];
        length=length+dlength;
    end

    T=T*at;
    if T<e
        break;
    end
end
x=XY(path,1);
y=XY(path,2);
plot(x,y,'-*');