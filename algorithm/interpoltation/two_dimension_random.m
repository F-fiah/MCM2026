%散乱数据的插值（已知n个节点(xi,yi,zi)）
% griddata函数
N = 200;
x = rand(N,1)*4*pi;
y = rand(N,1)*4*pi;
z = sin(x).*cos(y);  %随机数据

xi = linspace(min(x),max(x),100);
yi = linspace(min(y),max(y),100);
[Xi,Yi] = meshgrid(xi,yi);   %生成目标规则网格

Z1 = griddata(x,y,z,Xi,Yi,'nearest');  % 最近邻插值
Z2 = griddata(x,y,z,Xi,Yi,'linear');   % 线性插值
Z3 = griddata(x,y,z,Xi,Yi,'cubic');    % 三次插值，更光滑，少量超调，精度高
% Z4 = griddata(x,y,z,Xi,Yi,'makima');   % 修正Akima插值