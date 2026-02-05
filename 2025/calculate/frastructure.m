%% 基础设施负荷动态模型（剔除异常年份）
% 模型：dL/dt = β * V * (1 - L) - γ * I * L
% 剔除2020-2022年疫情异常数据

clear; clc; close all;

fprintf('=== 基础设施负荷动态模型（剔除异常年份） ===\n');
fprintf('模型: dL/dt = β*V*(1-L) - γ*I*L\n');
fprintf('剔除年份: 2020, 2021, 2022\n\n');

%% 1. 数据准备和异常年份剔除
% 读取游客数据
visitor_data = readmatrix('visitor.xlsx');
years_full = visitor_data(:, 1);
V_full = visitor_data(:, 2) / 1e6;  % 百万游客

% 读取基础设施数据
infra_data = readmatrix('frastructure.xlsx');
traffic_full = zeros(size(years_full));
water_full = zeros(size(years_full));

for i = 1:length(years_full)
    idx = find(infra_data(:, 1) == years_full(i));
    if ~isempty(idx)
        traffic_full(i) = infra_data(idx, 2);
        water_full(i) = infra_data(idx, 3);
    end
end

% 读取税收数据
tax_data = readmatrix('tax.xlsx');
tax_full = zeros(size(years_full));
total_full = zeros(size(years_full));

for i = 1:length(years_full)
    idx = find(tax_data(:, 1) == years_full(i));
    if ~isempty(idx)
        tax_full(i) = tax_data(idx, 2);
        total_full(i) = tax_data(idx, 3);
    end
end

%% 2. 剔除异常年份（2020-2022）
anomaly_years = [2020, 2021, 2022];
normal_mask = ~ismember(years_full, anomaly_years);

% 提取正常年份数据
years = years_full(normal_mask);
V = V_full(normal_mask);
traffic = traffic_full(normal_mask);
water = water_full(normal_mask);
tax = tax_full(normal_mask);
total = total_full(normal_mask);

fprintf('数据年份范围: %d-%d\n', min(years), max(years));
fprintf('剔除异常年份: 2020, 2021, 2022\n');
fprintf('正常年份数量: %d年\n\n', length(years));

%% 3. 计算基础设施负荷L
% 使用简单但合理的计算方法
% 负荷L = 当前使用量 / 设计容量

% 3.1 估计设计容量（基于历史峰值乘以安全系数）
safety_factor = 1.2;  % 20%安全余量
traffic_design = max(traffic) * safety_factor;
water_design = max(water) * safety_factor;

% 3.2 计算各部分负荷
traffic_load = traffic / traffic_design;
water_load = water / water_design;

% 3.3 综合负荷（加权平均）
L = 0.6 * traffic_load + 0.4 * water_load;

% 3.4 确保在合理范围内
L = min(max(L, 0.01), 0.95);

fprintf('负荷计算完成:\n');
fprintf('交通设计容量: %.1f (基于峰值%.1f, 安全系数%.1f)\n', ...
    traffic_design, max(traffic), safety_factor);
fprintf('水资源设计容量: %.1f (基于峰值%.1f, 安全系数%.1f)\n\n', ...
    water_design, max(water), safety_factor);

%% 4. 计算基础设施投资
I = 0.35 * tax;  % 35%税收用于基础设施

%% 5. 计算负荷变化率（使用简单但稳健的方法）
dt = 1;  % 时间间隔1年
dL_dt = zeros(size(L));

% 中心差分（对中间点）
for i = 2:length(L)-1
    dL_dt(i) = (L(i+1) - L(i-1)) / (2*dt);
end

% 边界处理
dL_dt(1) = (L(2) - L(1)) / dt;
dL_dt(end) = (L(end) - L(end-1)) / dt;

%% 6. 模型参数估计（使用正常年份数据）
fprintf('=== 模型参数估计（仅正常年份） ===\n');

% 模型：dL/dt = β*V*(1-L) - γ*I*L
% 可以重写为：dL/dt + γ*I*L = β*V*(1-L)
% 对于每个时间点：dL_dt_i = β*V_i*(1-L_i) - γ*I_i*L_i

% 使用最小二乘拟合
X = [V .* (1 - L), -I .* L];  % 设计矩阵
y = dL_dt;                   % 响应变量

% 线性回归
params = X \ y;
beta = params(1);
gamma = params(2);

fprintf('参数估计结果:\n');
fprintf('β = %.6f (游客影响系数)\n', beta);
fprintf('γ = %.6f (投资效率系数)\n', gamma);

% 计算R²
y_pred = X * params;
SS_res = sum((y - y_pred).^2);
SS_tot = sum((y - mean(y)).^2);
R2_fit = 1 - SS_res / SS_tot;
fprintf('参数拟合R² = %.4f\n\n', R2_fit);

%% 7. 模型模拟
fprintf('=== 模型模拟 ===\n');

function L_sim = simulate_infrastructure_model(beta, gamma, L0, V, I)
    % 模拟模型：dL/dt = β*V*(1-L) - γ*I*L
    L_sim = zeros(length(V), 1);
    L_sim(1) = L0;
    
    dt = 1;  % 时间步长1年
    for i = 1:length(V)-1
        dL = beta * V(i) * (1 - L_sim(i)) - gamma * I(i) * L_sim(i);
        L_sim(i+1) = L_sim(i) + dL * dt;
        
        % 确保在合理范围内
        L_sim(i+1) = min(max(L_sim(i+1), 0.01), 0.95);
    end
end

% 模拟
L0 = L(1);
L_sim = simulate_infrastructure_model(beta, gamma, L0, V, I);

%% 8. 模型评估
fprintf('=== 模型评估 ===\n');

% 计算拟合优度
SS_res_total = sum((L - L_sim).^2);
SS_tot_total = sum((L - mean(L)).^2);
R2 = 1 - SS_res_total / SS_tot_total;

RMSE = sqrt(mean((L - L_sim).^2));
MAE = mean(abs(L - L_sim));

fprintf('决定系数 R² = %.4f\n', R2);
fprintf('均方根误差 RMSE = %.4f\n', RMSE);
fprintf('平均绝对误差 MAE = %.4f\n\n', MAE);

% 详细对比
fprintf('详细对比（每5年显示）:\n');
fprintf('年份   实际L    模拟L    误差\n');
for i = 1:length(years)
    if mod(i, 5) == 1 || i == length(years)
        fprintf('%4d   %.3f   %.3f   %+.3f\n', ...
            years(i), L(i), L_sim(i), L_sim(i)-L(i));
    end
end

%% 9. 模型验证
fprintf('\n=== 模型验证 ===\n');

% 计算模拟的dL/dt
dL_dt_sim = beta * V .* (1 - L_sim) - gamma * I .* L_sim;

% 计算相关系数
corr_coeff = corr(dL_dt, dL_dt_sim);
fprintf('实际dL/dt与模拟dL/dt的相关系数: %.4f\n', corr_coeff);

% 计算平均绝对百分比误差
mask_nonzero = L > 0.01;
MAPE = mean(abs((L(mask_nonzero) - L_sim(mask_nonzero)) ./ L(mask_nonzero))) * 100;
fprintf('平均绝对百分比误差 MAPE: %.2f%%\n\n', MAPE);

%% 10. 可视化结果
figure('Position', [100, 100, 1200, 800]);

% 图1：负荷对比
subplot(2, 3, 1);
plot(years, L, 'b-', 'LineWidth', 2, 'DisplayName', '实际负荷');
hold on;
plot(years, L_sim, 'r--', 'LineWidth', 2, 'DisplayName', '模拟负荷');
xlabel('年份', 'FontSize', 12);
ylabel('基础设施负荷 L', 'FontSize', 12);
title(sprintf('基础设施负荷对比 (R²=%.3f)', R2), 'FontSize', 14);
legend('Location', 'best');
grid on;
xlim([min(years)-1, max(years)+1]);
ylim([0, 1]);

% 图2：游客数量和投资
subplot(2, 3, 2);
yyaxis left;
plot(years, V, 'b-', 'LineWidth', 2);
ylabel('游客数量 (百万)', 'FontSize', 12, 'Color', 'b');
yyaxis right;
plot(years, I, 'r-', 'LineWidth', 2);
ylabel('基础设施投资 (百万美元)', 'FontSize', 12, 'Color', 'r');
xlabel('年份', 'FontSize', 12);
title('游客数量与基础设施投资', 'FontSize', 14);
grid on;
xlim([min(years)-1, max(years)+1]);

% 图3：残差分析
subplot(2, 3, 3);
residuals = L - L_sim;
bar(years, residuals, 'FaceColor', [0.7 0.7 0.7]);
hold on;
plot([min(years), max(years)], [0, 0], 'k-', 'LineWidth', 1.5);
plot([min(years), max(years)], [RMSE, RMSE], 'r--', 'LineWidth', 1);
plot([min(years), max(years)], [-RMSE, -RMSE], 'r--', 'LineWidth', 1);
xlabel('年份', 'FontSize', 12);
ylabel('残差 (L - L_{sim})', 'FontSize', 12);
title(sprintf('残差分析 (RMSE=%.3f)', RMSE), 'FontSize', 14);
grid on;
xlim([min(years)-1, max(years)+1]);

% 图4：dL/dt对比
subplot(2, 3, 4);
scatter(dL_dt, dL_dt_sim, 50, 'b', 'filled');
hold on;
plot([min(dL_dt), max(dL_dt)], [min(dL_dt), max(dL_dt)], 'k--', 'LineWidth', 1.5);
xlabel('实际 dL/dt', 'FontSize', 12);
ylabel('模拟 dL/dt', 'FontSize', 12);
title(sprintf('dL/dt对比 (相关系数=%.3f)', corr_coeff), 'FontSize', 14);
grid on;

% 图5：参数敏感性分析
subplot(2, 3, 5);
param_range = 0.5:0.05:1.5;
beta_test = beta * param_range;
gamma_test = gamma * param_range;
error_beta = zeros(size(param_range));
error_gamma = zeros(size(param_range));

for i = 1:length(param_range)
    % 测试β变化
    L_temp = simulate_infrastructure_model(beta_test(i), gamma, L0, V, I);
    error_beta(i) = sqrt(mean((L - L_temp).^2));
    
    % 测试γ变化
    L_temp = simulate_infrastructure_model(beta, gamma_test(i), L0, V, I);
    error_gamma(i) = sqrt(mean((L - L_temp).^2));
end

plot(param_range*100, error_beta, 'b-o', 'LineWidth', 2, 'MarkerSize', 6, 'DisplayName', 'β变化');
hold on;
plot(param_range*100, error_gamma, 'r-s', 'LineWidth', 2, 'MarkerSize', 6, 'DisplayName', 'γ变化');
xlabel('参数变化 (%)', 'FontSize', 12);
ylabel('RMSE', 'FontSize', 12);
title('参数敏感性分析', 'FontSize', 14);
legend('Location', 'best');
grid on;

% 图6：平衡点分析
subplot(2, 3, 6);
% 计算理论平衡点：dL/dt = 0 => β*V*(1-L) = γ*I*L => L_eq = β*V/(β*V + γ*I)
L_eq = (beta * V) ./ (beta * V + gamma * I);

plot(years, L, 'b-', 'LineWidth', 2, 'DisplayName', '实际负荷');
hold on;
plot(years, L_eq, 'g-.', 'LineWidth', 2, 'DisplayName', '理论平衡点');
plot(years, L_sim, 'r--', 'LineWidth', 2, 'DisplayName', '模拟负荷');
xlabel('年份', 'FontSize', 12);
ylabel('负荷 L', 'FontSize', 12);
title('实际负荷与理论平衡点', 'FontSize', 14);
legend('Location', 'best');
grid on;
xlim([min(years)-1, max(years)+1]);
ylim([0, 1]);

%% 11. 投资策略分析
fprintf('=== 投资策略分析 ===\n');

% 计算当前状况（使用最后一年数据）
current_year = years(end);
current_V = V(end);
current_L = L_sim(end);
current_I = I(end);

% 计算维持当前负荷所需投资
% 从平衡条件：β*V*(1-L) = γ*I*L
% => I_required = (β*V*(1-L)) / (γ*L)
I_required = (beta * current_V * (1 - current_L)) / (gamma * current_L);

fprintf('当前状况 (%d年):\n', current_year);
fprintf('  游客数量: %.2f 百万\n', current_V);
fprintf('  当前负荷: %.3f\n', current_L);
fprintf('  当前投资: %.2f 百万美元\n', current_I);
fprintf('  维持当前负荷所需投资: %.2f 百万美元\n\n', I_required);

if I_required > current_I
    deficit = I_required - current_I;
    fprintf('投资缺口: %.2f 百万美元/年\n', deficit);
    fprintf('需要增加投资: %.1f%%\n\n', (deficit/current_I)*100);
    
    % 政策建议
    fprintf('政策建议:\n');
    fprintf('  1. 增加基础设施投资 %.2f 百万美元/年\n', deficit);
    
    % 替代方案：限制游客
    V_max = (gamma * current_I * current_L) / (beta * (1 - current_L));
    fprintf('  2. 或限制游客数量至 %.2f 百万以下\n', V_max);
    
    % 混合策略
    fprintf('  3. 混合策略:\n');
    fprintf('     - 增加投资至 %.2f 百万美元/年\n', current_I * 1.1);
    fprintf('     - 限制游客数量至 %.2f 百万\n', current_V * 0.95);
else
    fprintf('当前投资充足，负荷将逐渐降低\n');
    annual_reduction = beta * current_V * (1 - current_L) - gamma * current_I * current_L;
    fprintf('预计负荷每年下降: %.4f\n\n', annual_reduction);
end

%% 12. 模型验证（交叉验证）
fprintf('=== 交叉验证 ===\n');

% 使用留一法交叉验证
n = length(years);
pred_errors = zeros(n, 1);

for i = 1:n
    % 排除第i年的数据
    train_idx = setdiff(1:n, i);
    
    % 使用剩余数据重新拟合参数
    X_train = [V(train_idx) .* (1 - L(train_idx)), -I(train_idx) .* L(train_idx)];
    y_train = dL_dt(train_idx);
    
    % 检查X_train是否有足够数据
    if rank(X_train) < size(X_train, 2)
        pred_errors(i) = NaN;
        continue;
    end
    
    params_train = X_train \ y_train;
    beta_train = params_train(1);
    gamma_train = params_train(2);
    
    % 预测被排除的年份
    L_pred = simulate_infrastructure_model(beta_train, gamma_train, L0, V, I);
    pred_errors(i) = L(i) - L_pred(i);
end

% 计算交叉验证误差
valid_errors = pred_errors(~isnan(pred_errors));
cv_RMSE = sqrt(mean(valid_errors.^2));
cv_MAE = mean(abs(valid_errors));

fprintf('留一法交叉验证结果:\n');
fprintf('  CV-RMSE: %.4f\n', cv_RMSE);
fprintf('  CV-MAE: %.4f\n\n', cv_MAE);

fprintf('\n========== 模型构建完成 ==========\n');