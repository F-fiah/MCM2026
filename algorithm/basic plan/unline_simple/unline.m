format long g;
syms x1 x2;
profit = (339-0.01*x1-0.003*x2)*x1+(399-0.004*x1-0.01*x2)*x2-(400000+195*x1+225*x2);
profit=simplify(profit); %化简目标函数（合并同类项、消去冗余）
f1=diff(profit,x1);
f2=diff(profit,x2);
[x1_result,x2_result]=solve(f1,f2);
x1_result=round(double(x1_result));
x2_result=round(double(x2_result)); % double：将符号解转为双精度数值
                                    % round：四舍五入取整
profit_result = subs(profit, {x1,x2}, {x1_result, x2_result}); % 把符号表达式中的x1/x2替换为具体值（得到符号数值）
profit_result=double(profit_result);