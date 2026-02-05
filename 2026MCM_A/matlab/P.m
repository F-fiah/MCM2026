%% 电池功率限制分析
% 作者：AI助手
% 日期：2024-XX-XX
% 描述：分析电池最大允许功率和实际功率关系

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

%% 5. 计算OCV和最大允许功率
% 计算开路电压 vs. 时间
V_ocv = OCV_func(SOC);

% 计算最大允许功率P_max（使根号内的值为0）
% 公式: OCV² - 4R_i * (P_max/η) = 0 ⇒ P_max = (OCV² * η) / (4 * R_i)
P_max = (V_ocv.^2 * eta) ./ (4 * R_i);

% 创建实际功率曲线（您可自行修改此部分）
% 我们创建一个先上升后下降的实际功率曲线，确保与P_max有交叉
t_hours = t / 3600;  % 转换为小时
P_actual = 1.5 + 2.5 * sin(2 * pi * t_hours / (max(t_hours)/2)) .* exp(-0.1 * t_hours);

%% 6. 第一张图：最大允许功率和实际功率
figure('Position', [100, 100, 800, 600], 'Color', 'white');

% 绘制最大允许功率曲线
plot(t_hours, P_max, 'LineWidth', 3, 'Color', [0.1, 0.6, 0.9]);
hold on;

% 绘制实际功率曲线
plot(t_hours, P_actual, 'LineWidth', 3, 'Color', [0.9, 0.3, 0.2], 'LineStyle', '-');

% 美化图形
grid on; box on;
xlabel('Time (hours)', 'FontSize', 14, 'FontWeight', 'bold');
ylabel('Power (W)', 'FontSize', 14, 'FontWeight', 'bold');
title('Maximum Allowed Power vs. Actual Power', 'FontSize', 16, 'FontWeight', 'bold');
legend('Maximum Allowed Power (P_{max})', 'Actual Power (P_{actual})', ...
       'Location', 'northeast', 'FontSize', 12, 'Box', 'off');

% 设置坐标轴
xlim([0, max(t_hours)]);
ylim([0, max([max(P_max), max(P_actual)]) * 1.1]);

% 添加网格
ax = gca;
ax.GridLineStyle = '-';
ax.GridAlpha = 0.15;
ax.MinorGridLineStyle = ':';
ax.MinorGridAlpha = 0.05;
ax.XMinorGrid = 'on';
ax.YMinorGrid = 'on';

% 标记交叉点
% 找到实际功率超过最大允许功率的区域
exceed_idx = P_actual > P_max;
if any(exceed_idx)
    % 找到第一个交叉点
    cross_idx = find(diff(exceed_idx) > 0, 1);
    if ~isempty(cross_idx)
        scatter(t_hours(cross_idx), P_actual(cross_idx), 100, 'k', 'filled', 'LineWidth', 2);
        text(t_hours(cross_idx), P_actual(cross_idx)*1.05, 'First Cross Point', ...
             'FontSize', 11, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
    end
end

%% 7. 第二张图：修正后的功率
figure('Position', [200, 100, 800, 600], 'Color', 'white');

% 计算修正后的功率
P_corrected = min(P_actual, P_max);

% 找出实际功率被限制的区域（即实际功率 > 最大允许功率的区域）
limited_region = P_actual > P_max;

% 创建时间向量用于填充区域
t_limited = t_hours(limited_region);
t_unlimited = t_hours(~limited_region);

% 绘制修正后的功率曲线，用两种颜色表示
hold on;

% 绘制未被限制的部分（实际功率 ≤ 最大允许功率）
if any(~limited_region)
    plot(t_unlimited, P_corrected(~limited_region), 'LineWidth', 3.5, 'Color', [0.2, 0.8, 0.3]);
end

% 绘制被限制的部分（实际功率 > 最大允许功率）
if any(limited_region)
    plot(t_limited, P_corrected(limited_region), 'LineWidth', 3.5, 'Color', [0.9, 0.2, 0.2]);
end

% 绘制原始实际功率曲线作为参考（虚线）
plot(t_hours, P_actual, 'LineWidth', 1.5, 'Color', [0.5, 0.5, 0.5], 'LineStyle', '--');

% 绘制最大允许功率曲线作为参考（点线）
plot(t_hours, P_max, 'LineWidth', 1.5, 'Color', [0.5, 0.5, 0.5], 'LineStyle', ':');

% 填充被限制的区域
if any(limited_region)
    % 找到连续的区域
    region_start = [];
    region_end = [];
    in_region = false;
    
    for i = 1:length(limited_region)
        if limited_region(i) && ~in_region
            region_start = [region_start, i];
            in_region = true;
        elseif ~limited_region(i) && in_region
            region_end = [region_end, i-1];
            in_region = false;
        end
    end
    
    % 处理最后一个区域
    if in_region
        region_end = [region_end, length(limited_region)];
    end
    
    % 填充每个区域
    for i = 1:length(region_start)
        idx_range = region_start(i):region_end(i);
        fill([t_hours(idx_range), fliplr(t_hours(idx_range))], ...
             [P_corrected(idx_range)', fliplr(P_actual(idx_range)')], ...
             [1, 0.8, 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.3);
    end
end

% 美化图形
grid on; box on;
xlabel('Time (hours)', 'FontSize', 14, 'FontWeight', 'bold');
ylabel('Power (W)', 'FontSize', 14, 'FontWeight', 'bold');
title('Corrected Power with Limitation', 'FontSize', 16, 'FontWeight', 'bold');

% 创建自定义图例
h1 = plot(NaN, NaN, 'LineWidth', 3.5, 'Color', [0.2, 0.8, 0.3]);
h2 = plot(NaN, NaN, 'LineWidth', 3.5, 'Color', [0.9, 0.2, 0.2]);
h3 = plot(NaN, NaN, 'LineWidth', 1.5, 'Color', [0.5, 0.5, 0.5], 'LineStyle', '--');
h4 = plot(NaN, NaN, 'LineWidth', 1.5, 'Color', [0.5, 0.5, 0.5], 'LineStyle', ':');
legend([h1, h2, h3, h4], ...
       {'Unlimited Power (P_{actual} ≤ P_{max})', ...
        'Limited Power (P_{actual} > P_{max})', ...
        'Original Actual Power', ...
        'Maximum Allowed Power'}, ...
       'Location', 'northeast', 'FontSize', 10, 'Box', 'off');

% 设置坐标轴
xlim([0, max(t_hours)]);
ylim([0, max([max(P_actual), max(P_max)]) * 1.1]);

% 添加网格
ax = gca;
ax.GridLineStyle = '-';
ax.GridAlpha = 0.15;
ax.MinorGridLineStyle = ':';
ax.MinorGridAlpha = 0.05;
ax.XMinorGrid = 'on';
ax.YMinorGrid = 'on';

% 添加统计信息
unlimited_percentage = sum(~limited_region) / length(limited_region) * 100;
limited_percentage = sum(limited_region) / length(limited_region) * 100;

text(0.02, 0.98, sprintf('Unlimited: %.1f%%\nLimited: %.1f%%', unlimited_percentage, limited_percentage), ...
     'Units', 'normalized', 'FontSize', 11, 'FontWeight', 'bold', ...
     'VerticalAlignment', 'top', 'BackgroundColor', [0.95, 0.95, 0.95], ...
     'EdgeColor', [0.3, 0.3, 0.3], 'Margin', 5);

%% 8. 事件函数定义
function [value, isterminal, direction] = soc_events(t, soc)
    % 当SOC达到下限时停止仿真
    value = soc - 0.01;        % 当SOC低于1%时停止
    isterminal = 1;            % 停止积分
    direction = -1;            % 仅在下降时检测
end