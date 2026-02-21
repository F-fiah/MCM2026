table = readtable('C:\Users\17934\Desktop\campus_data.csv');
x0=linspace(1,200,200);
y0=table.Study_Hours;
F1=griddedInterpolant(x0,y0,'linear'); %线性插值
F2=griddedInterpolant(x0,y0,'spline'); %三次样条插值
%F2=griddedInterpolant(x0,y0,'spline','extrap'); 对超出数据范围的插值运算使用外推方法
F3=griddedInterpolant(x0,y0,'cubic'); %三次多项式插值
x=1:0.1:200;
y1=F1(x);
y2=F2(x);
subplot(1,2,1);
plot(x,y1);
title('线性插值');
subplot(1,2,2);
plot(x,y2);
title('三次样条插值');

%三次样条插值的另一种计算方式-csape函数
%pp=csape(x0,y0);
%pp1=finder(pp); %计算pp函数的导数
%pp1=fnint(pp); %计算pp函数的积分
%y3=fnval(pp,x) %计算pp函数的函数值