x0=[150 85 150 145 130 0];
y0=[140 85 155 50 150 0];
angle=[243 236 220.5 159 230 52];
distance=zeros(6,6);
for i=1:1:6
    for j=1:1:6
        if j<i
            distance(i,j)=distance(j,i);
        elseif i~=j
            distance(i,j)=sqrt((x0(i)-x0(j))^2+(y0(i)-y0(j))^2);
        end
    end
end
angle=angle*pi/180;
f = @(theta) sum(abs(theta));
con = @(theta) constraint_fun(theta, angle, distance);

[x,y] = fmincon(f,zeros(6,1),[],[],[],[],-(pi/6)*ones(6,1),(pi/6)*ones(6,1),con);

function [c,ceq] = constraint_fun(theta, angle, distance)
    c = [];  % 初始化约束为一维向量
    for i = 1:1:6
        for j = 1:1:6
            if i ~= j
                theta_new = pi/2 + (angle(i) + theta(i) + angle(j) + theta(j))/2;
                c = [c; 8 - distance(i,j)*theta_new];
            end
        end
    end
    ceq = [];
end