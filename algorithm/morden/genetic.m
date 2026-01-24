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
w=50; % 种群规模
g=100; % 进化代数

% 生成初始较优种群
J=zeros(w,102);
for k=1:1:w
    path=[1,randperm(100)+1,102];
    for t=1:1000
        flag=0; 
        % 遍历所有非相邻点对，判断反转路段是否缩短路径
        for m=1:100
            for n=m+2:1:101
                dl = d(path(m),path(n))+d(path(m+1),path(n+1))-d(path(m),path(m+1))-d(path(n),path(n+1));
                if dl<0
                    path(m+1:n)=path(n:-1:m+1);
                    flag=1;
                end
            end
        end
        if flag==0
            J(k,:)=path;
            break;  % 将局部最优路径存入种群矩阵J，J(k,:)对应第k条路径
        end
    end
    if flag==1
        J(k,:)=path;
    end
end

length=inf;
path=zeros(1,102);
for k=1:1:g
    A=J;

    % 基因突变
    change=rand(1,w); % 生成1*w的随机数矩阵所有元素均匀分布在[0,1)内
    for i=1:1:w
        if change(1,i)<0.1
            change(1,i)=1;
        else
            change(1,i)=0;
        end
    end % 突变的个体
    B=[];
    for i=1:1:w
        if change(1,i)==1
            site=randi([2,101],1,3); % 生成3个分割点,将路径分为4段
            site=sort(site); % 升序排序
            C=A(i,:);
            C=[C(1:site(1)-1),C(site(2)+1:site(3)),C(site(1):site(2)),C(site(3)+1:102)];
            B=[C;B];
        end
    end

    G=[J;B];

    % 自然选择
    num=size(G,1);
    long=zeros(1,num);
    for i=1:1:num
        l=0;
        for j=1:1:101
            l=l+d(G(i,j),G(i,j+1));
        end
        long(i)=l;
        if l<length
            length=l;
            path=G(i,:);
        end
    end
    [slong,ind]=sort(long);
    J=G(ind(1:w),:);
end
x=XY(path,1);
y=XY(path,2);
plot(x,y,'-*');