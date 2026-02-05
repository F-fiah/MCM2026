%% 电池SOC仿真 - 简化版本
% 作者：AI助手
% 日期：2024-XX-XX
% 描述：使用指数多项式OCV模型的电池SOC仿真
% 输出：SOC vs. 时间和OCV vs. 时间图

clear; close all; clc;

%% 1. 参数设置
% 电池参数
Q_max = 4747 * 10^(-3) * 3600;  % 转换为A·s (4747 mAh → 17089.2 A·s)
R_i = 0.05;                     % 内阻 (Ω)
eta = 0.98;                     % 效率系数
P_total = 3;                    % 总功率 (W)

% OCV-SOC函数参数
a1 = 3.679;
b1 = -0.1101;
a2 = -0.2528;
b2 = -6.829;
c = 0.9386;

% 仿真时间设置
t_start = 0;                    % 起始时间 (s)
t_end = 10 * 3600;              % 终止时间 (10小时，单位s)
SOC0 = 1;                       % 初始SOC (100%)

%% 2. 定义OCV-SOC函数（指数多项式模型）
% OCV = a1*exp(b1*SOC) + a2*exp(b2*SOC) + c*(SOC)^2
OCV_func = @(soc) a1*exp(b1*soc) + a2*exp(b2*soc) + c*(soc).^2;

%% 3. 定义SOC微分方程
% 方程: dSOC/dt = -1/Q_max * [OCV - sqrt(OCV² - 4*R_i*P_total/η)] / (2*R_i)
soc_ode = @(t, soc) -1/Q_max * (OCV_func(soc) - ...
              sqrt(max(OCV_func(soc)^2 - 4*R_i*P_total/eta, 0))) / (2*R_i);

%% 4. 求解微分方程
% 设置ode求解器选项
options = odeset('RelTol', 1e-6, 'AbsTol', 1e-9, ...
                 'MaxStep', 60, 'Events', @(t, soc) soc_events(t, soc));

% 使用ode45求解
[t, SOC] = ode45(soc_ode, [t_start, t_end], SOC0, options);

%% 5. 计算OCV vs. 时间
% 计算开路电压 vs. 时间
V_ocv = OCV_func(SOC);

%% 6. 创建专业可视化
% 设置全局图形参数
set(groot, 'DefaultAxesFontSize', 12);
set(groot, 'DefaultTextFontSize', 14);
set(groot, 'DefaultLineLineWidth', 2.5);

% 创建图形窗口
figure('Position', [100, 100, 1200, 500], 'Color', 'white');

% 颜色方案
blue_color = [0.1, 0.4, 0.8];
green_color = [0.2, 0.7, 0.3];

%% 6.1 SOC vs. 时间图
subplot(1, 2, 1);
plot(t/3600, SOC*100, 'LineWidth', 3, 'Color', blue_color);
grid on; box on;

% 美化坐标轴
xlabel('Time (hours)', 'FontSize', 14, 'FontWeight', 'bold');
ylabel('State of Charge (%)', 'FontSize', 14, 'FontWeight', 'bold');
title('Battery SOC vs. Time at 25°C', 'FontSize', 16, 'FontWeight', 'bold');

% 设置坐标轴范围
xlim([0, max(t)/3600]);
ylim([0, 100]);

% 添加网格
ax = gca;
ax.GridLineStyle = '-';
ax.GridAlpha = 0.15;
ax.MinorGridLineStyle = ':';
ax.MinorGridAlpha = 0.05;
ax.XMinorGrid = 'on';
ax.YMinorGrid = 'on';
ax.GridColor = [0.3, 0.3, 0.3];

%% 6.2 OCV vs. 时间图
subplot(1, 2, 2);
plot(t/3600, V_ocv, 'LineWidth', 3, 'Color', green_color);
grid on; box on;

% 美化坐标轴
xlabel('Time (hours)', 'FontSize', 14, 'FontWeight', 'bold');
ylabel('Open Circuit Voltage (V)', 'FontSize', 14, 'FontWeight', 'bold');
title('Battery OCV vs. Time at 25°C', 'FontSize', 16, 'FontWeight', 'bold');

% 设置坐标轴范围
xlim([0, max(t)/3600]);
ylim([min(V_ocv)-0.05, max(V_ocv)+0.05]);

% 添加网格
ax = gca;
ax.GridLineStyle = '-';
ax.GridAlpha = 0.15;
ax.MinorGridLineStyle = ':';
ax.MinorGridAlpha = 0.05;
ax.XMinorGrid = 'on';
ax.YMinorGrid = 'on';
ax.GridColor = [0.3, 0.3, 0.3];

%% 8. 调整布局
% 调整子图位置以获得更好的间距
subplot(1, 2, 1);
pos1 = get(gca, 'Position');
set(gca, 'Position', [pos1(1)-0.04, pos1(2), pos1(3)*0.95, pos1(4)]);

subplot(1, 2, 2);
pos2 = get(gca, 'Position');
set(gca, 'Position', [pos2(1)-0.02, pos2(2), pos2(3)*0.95, pos2(4)]);

%% 9. 打印仿真结果
fprintf('================================================================\n');
fprintf('               Battery SOC Simulation Results\n');
fprintf('================================================================\n\n');
fprintf('Simulation Parameters:\n');
fprintf('  Q_max = %.0f mAh, R_i = %.3f Ω\n', Q_max/3.6*1000, R_i);
fprintf('  η = %.2f, P = %.1f W\n', eta, P_total);
fprintf('  OCV(SOC) = %.3f·exp(%.4f·SOC) + %.4f·exp(%.3f·SOC) + %.4f·SOC²\n', a1, b1, a2, b2, c);
fprintf('\nSimulation Results:\n');
fprintf('  Discharge Time: %.2f hours\n', max(t)/3600);
fprintf('  Initial SOC: %.1f%%, Final SOC: %.1f%%\n', SOC(1)*100, SOC(end)*100);
fprintf('  Initial OCV: %.3f V, Final OCV: %.3f V\n', V_ocv(1), V_ocv(end));
fprintf('  Minimum OCV: %.3f V\n', min(V_ocv));
fprintf('================================================================\n');

%% 10. 保存图形（可选）
% print('Battery_SOC_OCV_Simulation.png', '-dpng', '-r300');
% savefig('Battery_SOC_OCV_Simulation.fig');

%% 事件函数定义
function [value, isterminal, direction] = soc_events(t, soc)
    % 当SOC达到下限时停止仿真
    value = soc - 0.01;        % 当SOC低于1%时停止
    isterminal = 1;            % 停止积分
    direction = -1;            % 仅在下降时检测
end