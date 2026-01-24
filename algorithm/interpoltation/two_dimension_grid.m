x0=linspace(0, 4*pi, 10);
y0=linspace(0, 4*pi, 10);
[x,y]=meshgrid(x0,y0); %生成二维网络矩阵，x(i,j)是第 i 行 j 列网格点的 x 坐标，y(i,j)是第 i 行 j 列网格点的 y 坐标
z=sin(x).*cos(y);

%将meshgrid格式转化成ndgrid格式（meshgrid和ndgrid的网格结构是 "行和列颠倒" 的）,适配griddedInterpolant
x=x';
y=y';
z=z';

% griddedInterpolant函数实现二维插值,x,y,z是同型的二维矩阵，z(i,j)是坐标点(x(i,j), y(i,j))对应的函数值
F1=griddedInterpolant(x,y,z,'linear'); %双线性插值
F2=griddedInterpolant(x,y,z,'spline'); %样条插值
F3=griddedInterpolant(x,y,z,'makima'); %修正 Akima 插值
F4=griddedInterpolant(x,y,z,'cubic'); %三次插值