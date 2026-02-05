clear; clc; close all;
fprintf('=== 环境质量参数拟合（修正模型） ===\n\n');

%% 1. 数据准备
years = 1976:2025;
years = years';

% 冰川面积数据（平方公里）
Area = [55.0; 54.7; 54.4; 54.1; 53.8; 53.5; 53.2; 52.9; 52.5; 52.0; 
        51.5; 51.0; 50.5; 50.0; 49.4; 48.8; 48.2; 47.6; 47.0; 46.3;
        45.6; 44.9; 44.2; 43.5; 42.7; 41.9; 41.1; 40.3; 39.5; 38.7;
        37.8; 36.9; 36.0; 35.1; 34.2; 33.3; 32.4; 31.5; 30.6; 29.7;
        28.8; 27.9; 27.0; 26.0; 25.0; 24.0; 23.0; 22.0; 21.0; 20.0];

% 游客数据（人次）
Visitors = [120000; 125000; 130000; 135000; 140000; 145000; 150000; 155000; 160000; 170000;
            180000; 190000; 200000; 210000; 220000; 235000; 250000; 265000; 280000; 300000;
            320000; 340000; 360000; 400000; 450000; 470000; 480000; 490000; 500000; 510000;
            520000; 530000; 540000; 510000; 525000; 545000; 560000; 575000; 590000; 605000;
            630000; 655000; 680000; 700000; 120000; 250000; 620000; 680000; 710000; 730000];

%% 2. 关键修正：重新定义模型
% 正确模型：dE/dt = -a * (E - E_min) - λ * V * E
% 其中：a > 0 表示自然退化率（由于气候变暖）
%       λ > 0 表示游客影响系数
%       E_min 是环境质量下限（冰川可能的最小面积归一化值）
% 解释：即使没有游客(V=0)，环境也会自然退化

fprintf('=== 模型修正说明 ===\n');
fprintf('原模型: dE/dt = a*E*(1-E) - λ*V （假设自然恢复）\n');
fprintf('修正模型: dE/dt = -a*(E-E_min) - λ*V*E （考虑自然退化）\n\n');

%% 3. 数据预处理
% 3.1 环境质量归一化（0-1），但考虑E_min
E_max = max(Area);
E_min_actual = min(Area);
fprintf('冰川面积范围: %.1f - %.1f 平方公里\n', E_min_actual, E_max);

% 归一化：E = (Area - E_min_actual) / (E_max - E_min_actual)
E_raw = (Area - E_min_actual) / (E_max - E_min_actual);
E_raw = max(min(E_raw, 1), 0);  % 确保在[0,1]范围内

% 平滑处理（5年移动平均）
E = movmean(E_raw, 5);

% 3.2 游客数据处理（标准化）
V_raw = Visitors;
V_mean = mean(V_raw);
V_std = std(V_raw);
V = (V_raw - V_mean) / V_std;  % Z-score标准化

% 3.3 识别异常年份（2020-2022疫情期）
normal_mask = true(length(years), 1);
anomaly_years = [2020, 2021, 2022];
for i = 1:length(years)
    if any(years(i) == anomaly_years)
        normal_mask(i) = false;
    end
end

fprintf('剔除异常年份: 2020-2022\n');
fprintf('使用数据点: %d/%d\n', sum(normal_mask), length(years));

%% 4. 计算变化率（使用更精确的方法）
fprintf('\n=== 计算环境质量变化率 ===\n');

% 使用Savitzky-Golay滤波器同时平滑和求导
order = 2;  % 多项式阶数
framelen = 7;  % 窗口长度
[~, dE_dt] = sgolaydiff(E, order, framelen);

% 可视化检查
figure('Position', [100, 100, 800, 400]);
subplot(1,2,1);
plot(years, E, 'b-', 'LineWidth', 2);
xlabel('年份'); ylabel('环境质量 E');
title('环境质量时间序列'); grid on;

subplot(1,2,2);
plot(years, dE_dt, 'r-', 'LineWidth', 2);
xlabel('年份'); ylabel('dE/dt');
title('环境质量变化率'); grid on;

%% 5. 参数估计（使用修正模型）
fprintf('\n=== 参数估计（修正模型） ===\n');

% 5.1 定义修正模型的目标函数
function loss = corrected_loss(params, E, V, dE_dt_obs, normal_mask)
    % 参数：params = [a, lambda]
    % a: 自然退化率 (>0)
    % lambda: 游客影响系数 (>0)
    
    a = abs(params(1));
    lambda = abs(params(2));
    
    % 计算模拟的dE/dt（修正模型）
    E_min = 0;  % 归一化后的最小值
    dE_dt_sim = -a * (E - E_min) - lambda * V .* E;
    
    % 只使用正常年份
    residuals = dE_dt_obs(normal_mask) - dE_dt_sim(normal_mask);
    
    % 加权最小二乘（近期数据权重更高）
    n = length(residuals);
    weights = linspace(0.8, 1.2, n)';  % 近期数据权重稍高
    
    % 计算损失
    loss = sum(weights .* residuals.^2) / n;
    
    % 添加正则化防止过拟合
    loss = loss + 0.001 * (a^2 + lambda^2);
    
    % 确保数值稳定
    if isnan(loss) || isinf(loss)
        loss = 1e10;
    end
end

% 辅助函数：Savitzky-Golay微分
function [E_smooth, dE_dt] = sgolaydiff(E, order, framelen)
    % 使用Savitzky-Golay滤波器平滑并求导
    n = length(E);
    E_smooth = sgolayfilt(E, order, framelen);
    
    % 使用中心差分计算导数
    dE_dt = zeros(n, 1);
    for i = 2:n-1
        dE_dt(i) = (E_smooth(i+1) - E_smooth(i-1)) / 2;
    end
    dE_dt(1) = E_smooth(2) - E_smooth(1);
    dE_dt(end) = E_smooth(end) - E_smooth(end-1);
end

% 5.2 使用非线性最小二乘拟合
initial_guess = [0.02, 0.01];  % [a, lambda]
lb = [1e-6, 1e-6];  % 下界（必须为正）
ub = [0.5, 0.5];    % 上界

fprintf('初始猜测: a=%.4f, lambda=%.4f\n', initial_guess(1), initial_guess(2));

% 使用lsqcurvefit
options = optimoptions('lsqcurvefit', ...
    'Display', 'iter', ...
    'Algorithm', 'trust-region-reflective', ...
    'MaxIterations', 200, ...
    'FunctionTolerance', 1e-8);

% 定义模型函数
model_func = @(params, t) -params(1) * (E - 0) - params(2) * V .* E;

% 拟合
fprintf('开始拟合...\n');
[params_opt, resnorm, residual, exitflag, output] = lsqcurvefit(...
    model_func, initial_guess, [], dE_dt, lb, ub, options);

a_opt = abs(params_opt(1));
lambda_opt = abs(params_opt(2));

fprintf('\n=== 拟合结果 ===\n');
fprintf('退出标志: %d\n', exitflag);
fprintf('残差平方和: %.6f\n', resnorm);
fprintf('最优参数 a = %.6f\n', a_opt);
fprintf('最优参数 lambda = %.6f\n', lambda_opt);

%% 6. 模型模拟（修正模型）
fprintf('\n=== 模型模拟 ===\n');

function E_sim = simulate_corrected_model(a, lambda, E0, V, T)
    % 模拟修正模型：dE/dt = -a*(E-E_min) - λ*V*E
    E_sim = zeros(T, 1);
    E_sim(1) = E0;
    E_min = 0;
    
    dt = 1;  % 年
    for t = 1:T-1
        dE = -a * (E_sim(t) - E_min) - lambda * V(t) * E_sim(t);
        E_sim(t+1) = E_sim(t) + dE * dt;
        
        % 保持边界
        E_sim(t+1) = max(0, min(1, E_sim(t+1)));
    end
end

% 模拟整个时间序列
E_sim = simulate_corrected_model(a_opt, lambda_opt, E(1), V, length(E));

%% 7. 模型评估（仅正常年份）
fprintf('\n=== 模型评估 ===\n');

% 只计算正常年份
E_normal = E(normal_mask);
E_sim_normal = E_sim(normal_mask);

% 计算评估指标
SS_res = sum((E_normal - E_sim_normal).^2);
SS_tot = sum((E_normal - mean(E_normal)).^2);

if SS_tot > 0
    R2 = 1 - SS_res / SS_tot;
else
    R2 = 0;
end

RMSE = sqrt(mean((E_normal - E_sim_normal).^2));
MAE = mean(abs(E_normal - E_sim_normal));

% 计算平均绝对百分比误差（MAPE）
mask_nonzero = E_normal > 0.01;  % 避免除以0
if any(mask_nonzero)
    MAPE = mean(abs((E_normal(mask_nonzero) - E_sim_normal(mask_nonzero)) ./ E_normal(mask_nonzero))) * 100;
else
    MAPE = NaN;
end

fprintf('决定系数 R² = %.4f\n', R2);
fprintf('均方根误差 RMSE = %.4f\n', RMSE);
fprintf('平均绝对误差 MAE = %.4f\n', MAE);
fprintf('平均绝对百分比误差 MAPE = %.2f%%\n', MAPE);

%% 8. 结果解释和预测
fprintf('\n=== 模型解释 ===\n');
fprintf('1. 自然退化率 a = %.4f/年\n', a_opt);
fprintf('   意味着即使没有游客，环境质量每年自然下降 %.2f%%\n', a_opt * 100);

% 计算游客贡献的退化率
V_mean_recent = mean(V(years >= 2010 & years <= 2019));  % 2010-2019年平均
tourist_degradation = lambda_opt * V_mean_recent;
fprintf('2. 游客影响系数 λ = %.6f\n', lambda_opt);
fprintf('   在平均游客水平下，游客造成的环境质量下降: %.2f%%/年\n', tourist_degradation * 100);

total_degradation = a_opt + tourist_degradation;
fprintf('3. 总退化率: %.2f%%/年\n', total_degradation * 100);

% 预测未来
fprintf('\n=== 未来预测 ===\n');
future_years = 2026:2035;
n_future = length(future_years);

% 三种游客情景
V_scenarios = struct();
V_scenarios.low = ones(n_future, 1) * V(end) * 0.7;      % 减少30%
V_scenarios.medium = ones(n_future, 1) * V(end);         % 保持当前
V_scenarios.high = ones(n_future, 1) * V(end) * 1.3;     % 增加30%

% 模拟未来
E0_future = E_sim(end);
for scenario = fieldnames(V_scenarios)'
    V_future = V_scenarios.(scenario{1});
    E_future = simulate_corrected_model(a_opt, lambda_opt, E0_future, V_future, n_future+1);
    V_scenarios.(scenario{1}) = struct('V', V_future, 'E', E_future(2:end));
    
    % 计算未来10年总变化
    total_change = (E_future(end) - E0_future) * 100;
    fprintf('情景 %-6s: 环境质量变化 %.1f%%\n', scenario{1}, total_change);
end

%% 9. 改进的可视化
figure('Position', [50, 50, 1400, 900]);

% 图1：环境质量对比（主图）
subplot(3, 3, [1, 2, 4, 5]);
h1 = plot(years, E, 'b-', 'LineWidth', 3); hold on;
h2 = plot(years, E_sim, 'r--', 'LineWidth', 2.5);
% 标记异常年份
for yr = anomaly_years
    idx = find(years == yr, 1);
    if ~isempty(idx)
        plot(years(idx), E(idx), 'ko', 'MarkerSize', 10, 'LineWidth', 2);
    end
end

% 添加未来预测
colors = [0 0.5 0; 0 0 1; 1 0 0];  % 绿、蓝、红
scenario_names = fieldnames(V_scenarios);
for i = 1:length(scenario_names)
    scenario = scenario_names{i};
    E_future = V_scenarios.(scenario).E;
    plot(future_years, E_future, '-', 'Color', colors(i,:), 'LineWidth', 2);
end

plot([2025, 2025], [0, 1], 'k--', 'LineWidth', 1.5);
xlabel('年份', 'FontSize', 14, 'FontWeight', 'bold');
ylabel('环境质量 (归一化)', 'FontSize', 14, 'FontWeight', 'bold');
title(sprintf('环境质量变化: 历史与预测 (R²=%.3f)', R2), 'FontSize', 16, 'FontWeight', 'bold');
legend([h1, h2, plot(nan, nan, 'k-', 'LineWidth', 2)], ...
    {'实际值', '模拟值', '异常年份', '未来预测-低客流', '未来预测-中客流', '未来预测-高客流'}, ...
    'Location', 'best', 'FontSize', 10);
grid on; box on;
xlim([1975, 2036]);
ylim([0, 1]);

% 图2：残差分析
subplot(3, 3, 3);
residuals = E - E_sim;
bar(years(normal_mask), residuals(normal_mask), 'FaceColor', [0.7 0.7 0.7]);
hold on;
bar(years(~normal_mask), residuals(~normal_mask), 'FaceColor', [1 0.6 0.6]);
plot([min(years), max(years)], [0, 0], 'k-', 'LineWidth', 1.5);
xlabel('年份', 'FontSize', 12);
ylabel('残差', 'FontSize', 12);
title('残差分析', 'FontSize', 14);
grid on;
xlim([1975, 2026]);

% 图3：参数贡献分析
subplot(3, 3, 6);
contributions = zeros(length(years), 2);
for i = 1:length(years)
    contributions(i, 1) = -a_opt * (E(i) - 0);  % 自然退化贡献
    contributions(i, 2) = -lambda_opt * V(i) * E(i);  % 游客贡献
end

area(years, contributions);
xlabel('年份', 'FontSize', 12);
ylabel('dE/dt 贡献', 'FontSize', 12);
title('退化因素贡献分解', 'FontSize', 14);
legend('自然退化', '游客影响', 'Location', 'best');
grid on;
xlim([1975, 2026]);

% 图4：游客数量与环境质量关系
subplot(3, 3, 7);
scatter(V(normal_mask), E(normal_mask), 50, years(normal_mask), 'filled');
hold on;
scatter(V(~normal_mask), E(~normal_mask), 80, 'k', 'x', 'LineWidth', 2);
colorbar; colormap(jet);
xlabel('标准化游客数量', 'FontSize', 12);
ylabel('环境质量', 'FontSize', 12);
title('游客 vs 环境质量', 'FontSize', 14);
grid on;

% 图5：敏感性分析
subplot(3, 3, 8);
% 分析参数变化对最终环境质量的影响
param_variation = 0.5:0.05:1.5;  % 参数变化比例
E_final = zeros(length(param_variation), 2);

for i = 1:length(param_variation)
    % 改变a
    a_test = a_opt * param_variation(i);
    E_temp = simulate_corrected_model(a_test, lambda_opt, E(1), V, length(E));
    E_final(i, 1) = E_temp(end);
    
    % 改变lambda
    lambda_test = lambda_opt * param_variation(i);
    E_temp = simulate_corrected_model(a_opt, lambda_test, E(1), V, length(E));
    E_final(i, 2) = E_temp(end);
end

plot(param_variation*100, E_final(:,1)*100, 'b-o', 'LineWidth', 2); hold on;
plot(param_variation*100, E_final(:,2)*100, 'r-s', 'LineWidth', 2);
xlabel('参数变化 (%)', 'FontSize', 12);
ylabel('最终环境质量 (%)', 'FontSize', 12);
title('参数敏感性', 'FontSize', 14);
legend('自然退化率 a', '游客影响 λ', 'Location', 'best');
grid on;

% 图6：模型验证 - 与实际dE/dt对比
subplot(3, 3, 9);
dE_dt_sim = -a_opt * (E - 0) - lambda_opt * V .* E;
scatter(dE_dt(normal_mask), dE_dt_sim(normal_mask), 40, 'b', 'filled'); hold on;
scatter(dE_dt(~normal_mask), dE_dt_sim(~normal_mask), 60, 'r', 'x', 'LineWidth', 2);
plot([min(dE_dt), max(dE_dt)], [min(dE_dt), max(dE_dt)], 'k--', 'LineWidth', 1.5);
xlabel('实际 dE/dt', 'FontSize', 12);
ylabel('模拟 dE/dt', 'FontSize', 12);
title('模型验证', 'FontSize', 14);
grid on;

%% 10. 保存结果和报告
fprintf('\n=== 生成报告 ===\n');

% 计算各阶段平均退化率
periods = {1976:1985, 1986:1995, 1996:2005, 2006:2015, 2016:2025};
for p = 1:length(periods)
    mask = ismember(years, periods{p});
    if any(mask)
        E_start = E(find(mask, 1, 'first'));
        E_end = E(find(mask, 1, 'last'));
        degradation_rate = (E_start - E_end) / length(periods{p}) * 100;
        fprintf('时期 %d-%d: 平均退化率 = %.2f%%/年\n', ...
            periods{p}(1), periods{p}(end), degradation_rate);
    end
end

fprintf('\n========== 分析完成 ==========\n');
fprintf('总结：\n');
fprintf('1. 冰川退缩主要由气候变暖驱动（自然退化率 %.2f%%/年）\n', a_opt*100);
fprintf('2. 游客活动加速了退化，贡献约 %.2f%%/年的额外退化\n', tourist_degradation*100);
fprintf('3. 模型拟合度: R²=%.3f，可以接受\n', R2);
fprintf('4. 若不加控制，未来10年环境质量可能再下降 %.1f%%\n', (E_sim(end) - E_sim(end-10))*100);