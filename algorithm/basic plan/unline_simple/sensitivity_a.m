format long g;
syms x1 x2 a;
profit = (339-a*x1-0.003*x2)*x1+(399-0.004*x1-a*x2)*x2-(400000+195*x1+225*x2);
profit=simplify(profit);
f1=diff(profit,x1);
f2=diff(profit,x2);
[x1_result,x2_result]=solve(f1,f2);
a0=0.005:0.00003:0.015;
subplot(1,2,1);
X1 = double(subs(x1_result,a,a0));
plot(a0,X1);
subplot(1,2,2);
X2 = double(subs(x2_result,a,a0));
plot(a0,X2);

% 敏感性系数：a变化 1% 时，x1、x2、profit变化的百分比
dx1_a=diff(x1_result,a);
dx1_a0=double(subs(dx1_a,a,0.01));
sx1_a=dx1_a0*0.01/double(subs(x1_result,a,0.01));
dx2_a=diff(x2_result,a);
dx2_a0=double(subs(dx2_a,a,0.01));
sx2_a=dx2_a0*0.01/double(subs(x2_result,a,0.01));
profit_result=subs(profit,{x1,x2},{x1_result,x2_result});
dp_a=diff(profit_result,a);
dp_a0=double(subs(dp_a,a,0.01));
sp_a=dp_a0*0.01/double(subs(profit_result,a,0.01));
% 取a=0.011，验证瞬时敏感度的实用性
profit_old=double(subs(profit,{x1,x2,a},{4735,7043,0.011}));
profit_new=double(subs(profit,{x1,x2,a},{double(subs(x1_result,a,0.011)),double(subs(x2_result,a,0.011)),0.011}));
delta=(profit_new-profit_old)/profit_new;

fprintf('x1对a的弹性：%.4f（a变化1%%，x1变化%.2f%%）\n', sx1_a, sx1_a*100);
fprintf('x2对a的弹性：%.4f（a变化1%%，x2变化%.2f%%）\n', sx2_a, sx2_a*100);
fprintf('利润对a的弹性：%.4f（a变化1%%，利润变化%.2f%%）\n', sp_a, sp_a*100);
fprintf('a=0.011时，利润相对误差：%.4f%%\n',delta*100);