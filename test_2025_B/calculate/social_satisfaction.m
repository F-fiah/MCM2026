%% ==================== 可持续旅游模型：完整解决方案 ====================
% 基于真实数据（冰川、游客、税收、满意度）的可持续旅游模型
% 使用岭回归处理多重共线性，提供参数估计、敏感性分析和未来预测
% =====================================================================

clc; clear; close all;
warning('off', 'all'); % 关闭所有警告
addpath(genpath(pwd));

fprintf('========================================\n');
fprintf('可持续旅游模型 - JUNEAU, ALASKA\n');
fprintf('========================================\n\n');

%% 1. 数据加载与预处理
fprintf('1. 数据加载与预处理...\n');

% 加载所有数据集
glacier = readtable('glacier.xlsx', 'VariableNamingRule', 'preserve');
visitor = readtable('visitor.xlsx', 'VariableNamingRule', 'preserve');
tax = readtable('tax.xlsx', 'VariableNamingRule', 'preserve');
satisfaction = readtable('society.xlsx', 'VariableNamingRule', 'preserve');

% 重命名列以便访问
glacier.Properties.VariableNames = {'Year', 'Area', 'Lower', 'Upper'};
visitor.Properties.VariableNames = {'Year', 'Visitors', 'Lower_CI', 'Upper_CI'};
tax.Properties.VariableNames = {'year', 'tax_million', 'total_tourism_revenue_million'};
satisfaction.Properties.VariableNames = {'Year', 'S_index'};

% 提取2005-2019年数据（排除疫情异常期）
years_range = 2005:2019;
common_years = years_range;
n = length(common_years);

% 初始化数据矩阵
E = zeros(n, 1);      % 冰川面积（环境质量）
V = zeros(n, 1);      % 游客数量
R_tax = zeros(n, 1);  % 旅游税收（百万美元）
R_total = zeros(n, 1);% 旅游总收入（百万美元）
S = zeros(n, 1);      % 居民满意度指数

% 数据对齐和提取
for i = 1:n
    year = common_years(i);
    
    % 冰川面积
    idx = find(glacier.Year == year, 1);
    if ~isempty(idx)
        E(i) = glacier.Area(idx);
    end
    
    % 游客数量
    idx = find(visitor.Year == year, 1);
    if ~isempty(idx)
        V(i) = visitor.Visitors(idx);
    end
    
    % 税收和总收入
    idx = find(tax.year == year, 1);
    if ~isempty(idx)
        R_tax(i) = tax.tax_million(idx);
        R_total(i) = tax.total_tourism_revenue_million(idx);
    end
    
    % 居民满意度
    idx = find(satisfaction.Year == year, 1);
    if ~isempty(idx)
        S(i) = satisfaction.S_index(idx);
    end
end

% 检查并处理缺失值
if any(isnan([E, V, R_tax, R_total, S]))
    fprintf('  发现缺失值，使用线性插值填充...\n');
    E = fillmissing(E, 'linear');
    V = fillmissing(V, 'linear');
    R_tax = fillmissing(R_tax, 'linear');
    R_total = fillmissing(R_total, 'linear');
    S = fillmissing(S, 'linear');
end

fprintf('   数据年份: %d-%d (%d年数据)\n', min(common_years), max(common_years), n);
fprintf('   数据加载完成\n\n');

%% 2. 计算居民满意度变化率 (dS/dt)
fprintf('2. 计算居民满意度变化率...\n');

% 使用中心差分法计算dS/dt
dS_dt = zeros(n, 1);

% 中心差分（内部点）
for i = 2:n-1
    dS_dt(i) = (S(i+1) - S(i-1)) / 2;
end

% 端点处理（前向/后向差分）
dS_dt(1) = S(2) - S(1);
dS_dt(n) = S(n) - S(n-1);

% 使用移动平均平滑变化率（减少噪声）
window_size = 3;
dS_dt_smooth = movmean(dS_dt, window_size);

% 统计信息
fprintf('   变化率平均值: %.4f\n', mean(dS_dt_smooth));
fprintf('   变化率标准差: %.4f\n', std(dS_dt_smooth));
fprintf('   变化率范围: [%.4f, %.4f]\n', min(dS_dt_smooth), max(dS_dt_smooth));
fprintf('   计算完成\n\n');

%% 3. 构建回归模型的特征矩阵
fprintf('3. 构建特征矩阵...\n');

% 模型参数
N = 30000;          % 居民人口
V_comf = 15000;     % 舒适游客数（基于数据分析）

% 根据公式(4)构建特征：
% dS/dt = -ω*(V-V_comf) + η_S*I_S + θ*(R_total-R_tax)/N + μ*E

% 特征1: 游客压力项（注意负号已在X1中，因此ω应为正值）
X1 = -(V - V_comf);

% 特征2: 社区投资项 (I_S = 0.65 * 税收)
I_S = 0.65 * R_tax * 1e6;  % 转换为美元
X2 = I_S;

% 特征3: 居民净收入项
X3 = (R_total - R_tax) * 1e6 / N;  % 人均净收入（美元）

% 特征4: 环境质量项
X4 = E;

% 创建完整特征矩阵
X = [X1, X2, X3, X4];
Y = dS_dt_smooth;  % 响应变量

% 特征名称
feature_names = {'游客压力项 (-ω*(V-V_comf))', ...
                 '社区投资项 (η_S*I_S)', ...
                 '经济收益项 (θ*(R-R_tax)/N)', ...
                 '环境质量项 (μ*E)'};

fprintf('   特征矩阵维度: %d × %d\n', size(X));
fprintf('   响应变量维度: %d × 1\n', length(Y));
fprintf('   构建完成\n\n');

%% 4. 数据标准化与预处理
fprintf('4. 数据标准化与预处理...\n');

% 标准化特征矩阵（Z-score标准化）
mu_X = mean(X, 1);
sigma_X = std(X, 0, 1);
sigma_X(sigma_X == 0) = 1;  % 防止除以零
X_norm = (X - mu_X) ./ sigma_X;

% 标准化响应变量
Y_mean = mean(Y);
Y_std = std(Y);
Y_norm = (Y - Y_mean) / Y_std;

% 保存标准化参数
standardization.mu_X = mu_X;
standardization.sigma_X = sigma_X;
standardization.Y_mean = Y_mean;
standardization.Y_std = Y_std;

fprintf('   标准化完成\n');
fprintf('   特征均值: [%s]\n', num2str(mu_X, '%.2f '));
fprintf('   特征标准差: [%s]\n\n', num2str(sigma_X, '%.2f '));

%% 5. 多重共线性诊断
fprintf('5. 多重共线性诊断...\n');

% 计算方差膨胀因子(VIF)
n_features = size(X_norm, 2);
VIF = zeros(1, n_features);

for i = 1:n_features
    % 用其他特征回归第i个特征
    other_features = [1:i-1, i+1:n_features];
    X_temp = X_norm(:, other_features);
    y_temp = X_norm(:, i);
    
    % 普通最小二乘
    beta_temp = (X_temp' * X_temp) \ (X_temp' * y_temp);
    y_pred = X_temp * beta_temp;
    
    % 计算R²
    SS_res = sum((y_temp - y_pred).^2);
    SS_tot = sum((y_temp - mean(y_temp)).^2);
    R2 = 1 - SS_res / SS_tot;
    
    % 计算VIF
    VIF(i) = 1 / (1 - R2);
end

% 显示VIF结果
fprintf('   Variance Inflation Factors (VIF):\n');
for i = 1:n_features
    if VIF(i) > 10
        status = '严重共线性';
    elseif VIF(i) > 5
        status = '中等共线性';
    else
        status = '可接受';
    end
    fprintf('     %s: VIF = %.2f (%s)\n', feature_names{i}, VIF(i), status);
end
fprintf('\n');

%% 6. 正则化参数选择（交叉验证）
fprintf('6. 正则化参数选择（岭回归）...\n');

% 定义正则化参数范围
lambda_range = logspace(-3, 3, 50);  % 10^-3 到 10^3
k = 5;  % 5折交叉验证
cv_errors = zeros(length(lambda_range), 1);
indices = crossvalind('Kfold', length(Y_norm), k);

% 交叉验证选择最优λ
for lamda_idx = 1:length(lambda_range)
    lambda = lambda_range(lamda_idx);
    fold_errors = zeros(k, 1);
    
    for fold = 1:k
        % 分割数据
        test_idx = (indices == fold);
        train_idx = ~test_idx;
        
        X_train = X_norm(train_idx, :);
        Y_train = Y_norm(train_idx);
        X_test = X_norm(test_idx, :);
        Y_test = Y_norm(test_idx);
        
        % 岭回归
        I = eye(size(X_train, 2));
        beta_cv = (X_train' * X_train + lambda * I) \ (X_train' * Y_train);
        
        % 预测和误差计算
        Y_pred_cv = X_test * beta_cv;
        fold_errors(fold) = sqrt(mean((Y_test - Y_pred_cv).^2));
    end
    
    cv_errors(lamda_idx) = mean(fold_errors);
end

% 选择最优λ
[~, best_lamda_idx] = min(cv_errors);
best_lambda = lambda_range(best_lamda_idx);

fprintf('   最优正则化参数 λ = %.4f\n\n', best_lambda);

%% 7. 模型拟合与参数估计
fprintf('7. 模型拟合与参数估计...\n');

% 使用最优λ进行岭回归
I = eye(size(X_norm, 2));
beta_norm = (X_norm' * X_norm + best_lambda * I) \ (X_norm' * Y_norm);

% 将参数转换回原始尺度
beta_original = beta_norm .* (Y_std ./ sigma_X');

% 提取模型参数
omega = beta_original(1);     % 游客压力系数
eta_S = beta_original(2) / 1e6; % 社区投资系数（调整为每百万美元）
theta = beta_original(3);     % 经济收益系数
mu = beta_original(4);        % 环境质量系数

fprintf('   参数估计结果:\n');
fprintf('     ω  (游客压力系数) = %.6f\n', omega);
fprintf('     η_S(投资效果系数) = %.6f (每百万美元)\n', eta_S);
fprintf('     θ  (经济收益系数) = %.6f (每美元)\n', theta);
fprintf('     μ  (环境质量系数) = %.6f (每平方公里)\n\n', mu);

%% 8. 模型评估与验证
fprintf('8. 模型评估与验证...\n');

% 模型预测
Y_pred_norm = X_norm * beta_norm;
Y_pred = Y_pred_norm * Y_std + Y_mean;

% 计算评估指标
residuals = Y - Y_pred;
RMSE = sqrt(mean(residuals.^2));
MAE = mean(abs(residuals));
R2 = 1 - sum(residuals.^2) / sum((Y - mean(Y)).^2);
MAPE = mean(abs(residuals ./ max(abs(Y), 1e-6))) * 100;  % 避免除以零

% 统计显著性检验
n_obs = length(Y);
p = size(X_norm, 2);
sigma2 = sum(residuals.^2) / (n_obs - p - 1);
var_beta = sigma2 * diag(inv(X_norm' * X_norm + best_lambda * I));
t_stats = beta_norm ./ sqrt(var_beta);
p_values = 2 * (1 - tcdf(abs(t_stats), n_obs - p - 1));

% 显示模型性能
fprintf('   模型性能指标:\n');
fprintf('     RMSE (均方根误差): %.4f\n', RMSE);
fprintf('     MAE  (平均绝对误差): %.4f\n', MAE);
fprintf('     R²   (决定系数): %.4f\n', R2);
fprintf('     MAPE (平均绝对百分比误差): %.2f%%\n\n', MAPE);

fprintf('   参数统计显著性 (α=0.05):\n');
for i = 1:4
    if p_values(i) < 0.05
        sig_status = '**显著**';
    elseif p_values(i) < 0.1
        sig_status = '*边缘显著*';
    else
        sig_status = '不显著';
    end
    fprintf('     %s: t=%.3f, p=%.4f (%s)\n', ...
        feature_names{i}, t_stats(i), p_values(i), sig_status);
end
fprintf('\n');

%% 9. 敏感性分析
fprintf('9. 参数敏感性分析...\n');

% 使用原始尺度参数
param_names = {'ω', 'η_S', 'θ', 'μ'};
param_values = [omega, eta_S, theta, mu];

% 重新计算设计矩阵（原始尺度）
X_design = [-(V - V_comf), I_S, (R_total - R_tax)*1e6/N, E];
X_design = X_design(2:end, :); % 对齐Y（差分后少一年）

% 基线预测
Y_baseline = X_design * param_values';

% 计算各参数敏感性
sensitivity_metrics = zeros(4, 3);  % [灵敏度, 弹性, 重要性]

for i = 1:4
    % 参数增加10%
    params_plus = param_values;
    params_plus(i) = param_values(i) * 1.10;
    Y_plus = X_design * params_plus';
    
    % 参数减少10%
    params_minus = param_values;
    params_minus(i) = param_values(i) * 0.90;
    Y_minus = X_design * params_minus';
    
    % 计算灵敏度（预测变化的均方根误差）
    diff_plus = Y_plus - Y_baseline;
    diff_minus = Y_minus - Y_baseline;
    sensitivity = sqrt(mean([diff_plus; diff_minus].^2));
    
    % 计算弹性（参数变化1%导致预测变化百分比）
    non_zero_idx = abs(Y_baseline) > 1e-6;
    if sum(non_zero_idx) > 0
        pct_change = mean(abs((Y_plus(non_zero_idx) - Y_minus(non_zero_idx)) ./ ...
            Y_baseline(non_zero_idx))) * 100;
        elasticity = pct_change / 20;  % 参数变化了20%
    else
        elasticity = 0;
    end
    
    % 参数重要性（标准化系数的绝对值）
    importance = abs(beta_norm(i));
    
    % 存储结果
    sensitivity_metrics(i, :) = [sensitivity, elasticity, importance];
    
    fprintf('   参数 %s:\n', param_names{i});
    fprintf('     灵敏度: %.6f\n', sensitivity);
    fprintf('     弹性: %.4f%%\n', elasticity);
    fprintf('     重要性: %.4f\n', importance);
end

% 找出最重要的参数
[~, most_important_idx] = max(sensitivity_metrics(:, 3));
fprintf('\n   最重要的参数: %s (标准化系数绝对值 = %.4f)\n\n', ...
    param_names{most_important_idx}, sensitivity_metrics(most_important_idx, 3));

%% 10. 未来预测（2026-2030）
fprintf('10. 未来预测（2026-2030）...\n');

% 基于历史趋势进行预测
future_years = 2026:2030;
n_future = length(future_years);

% 计算历史趋势（过去5年平均变化率）
recent_years = 5;  % 使用最近5年
start_idx = n - recent_years + 1;

E_rate = mean(diff(E(start_idx:end))) / mean(E(start_idx:end-1));
V_rate = mean(diff(V(start_idx:end))) / mean(V(start_idx:end-1));
R_tax_rate = mean(diff(R_tax(start_idx:end))) / mean(R_tax(start_idx:end-1));
R_total_rate = mean(diff(R_total(start_idx:end))) / mean(R_total(start_idx:end-1));

% 初始化预测值
E_pred = zeros(n_future, 1);
V_pred = zeros(n_future, 1);
R_tax_pred = zeros(n_future, 1);
R_total_pred = zeros(n_future, 1);
S_pred = zeros(n_future, 1);

% 基于趋势预测
E_pred(1) = E(end) * (1 + E_rate);
V_pred(1) = V(end) * (1 + V_rate);
R_tax_pred(1) = R_tax(end) * (1 + R_tax_rate);
R_total_pred(1) = R_total(end) * (1 + R_total_rate);

for i = 2:n_future
    E_pred(i) = E_pred(i-1) * (1 + E_rate);
    V_pred(i) = V_pred(i-1) * (1 + V_rate);
    R_tax_pred(i) = R_tax_pred(i-1) * (1 + R_tax_rate);
    R_total_pred(i) = R_total_pred(i-1) * (1 + R_total_rate);
end

% 计算满意度预测
I_S_pred = 0.65 * R_tax_pred * 1e6;
X3_pred = (R_total_pred - R_tax_pred) * 1e6 / N;

% 初始化满意度预测
S_pred(1) = S(end);  % 从2025年开始

for i = 1:n_future
    % 计算dS/dt
    dS_dt_pred = omega * (V_pred(i) - V_comf) + ...
                 eta_S * I_S_pred(i) / 1e6 + ...
                 theta * X3_pred(i) + ...
                 mu * E_pred(i);
    
    % 更新满意度（如果是第一年，使用上一年的值加上变化）
    if i == 1
        S_pred(i) = S(end) + dS_dt_pred;
    else
        S_pred(i) = S_pred(i-1) + dS_dt_pred;
    end
end

% 显示预测结果
fprintf('   年份  游客数(万)  冰川面积(km²)  满意度指数\n');
fprintf('   ------------------------------------------\n');
for i = 1:n_future
    fprintf('   %4d  %9.0f  %12.1f  %12.1f\n', ...
        future_years(i), V_pred(i)/10000, E_pred(i), S_pred(i));
end
fprintf('\n');

%% 13. 模型总结
fprintf('13. 模型总结\n');
fprintf('   ========================================\n');
fprintf('   模型构建完成！\n\n');
fprintf('   关键发现:\n');
fprintf('     1. 最重要的影响因素: %s\n', param_names{most_important_idx});
fprintf('     2. 模型解释度 (R²): %.2f%%\n', R2*100);
fprintf('     3. 预测误差 (MAPE): %.2f%%\n', MAPE);
fprintf('\n');
fprintf('   政策建议:\n');
fprintf('     1. 关注参数 %s 的影响，制定针对性政策\n', param_names{most_important_idx});
fprintf('     2. 基于模型预测，合理规划未来旅游发展\n');
fprintf('     3. 定期更新模型参数，适应环境变化\n');
fprintf('\n');
fprintf('========================================\n');
fprintf('模型分析完成！\n');
fprintf('========================================\n');

%% 辅助函数：生成文本报告
function generate_report(results)
    report_file = 'juneau_model_report.txt';
    fid = fopen(report_file, 'w');
    
    fprintf(fid, '========================================\n');
    fprintf(fid, 'JUNEAU可持续旅游模型分析报告\n');
    fprintf(fid, '生成时间: %s\n', datestr(now));
    fprintf(fid, '========================================\n\n');
    
    fprintf(fid, '1. 模型参数估计结果\n');
    fprintf(fid, '   ---------------------------------\n');
    fprintf(fid, '   参数      估计值          单位\n');
    fprintf(fid, '   ---------------------------------\n');
    fprintf(fid, '   ω      %12.6f    (游客压力系数)\n', results.parameters.omega);
    fprintf(fid, '   η_S    %12.6f    (每百万美元投资效果)\n', results.parameters.eta_S);
    fprintf(fid, '   θ      %12.6f    (每美元经济收益效果)\n', results.parameters.theta);
    fprintf(fid, '   μ      %12.6f    (每平方公里环境质量效果)\n', results.parameters.mu);
    fprintf(fid, '\n');
    
    fprintf(fid, '2. 模型性能评估\n');
    fprintf(fid, '   ---------------------------------\n');
    fprintf(fid, '   指标          值\n');
    fprintf(fid, '   ---------------------------------\n');
    fprintf(fid, '   RMSE       %10.4f\n', results.performance.RMSE);
    fprintf(fid, '   MAE        %10.4f\n', results.performance.MAE);
    fprintf(fid, '   R²         %10.4f (%.1f%%)\n', results.performance.R2, results.performance.R2*100);
    fprintf(fid, '   MAPE       %10.2f%%\n', results.performance.MAPE);
    fprintf(fid, '\n');
    
    fprintf(fid, '3. 参数敏感性分析\n');
    fprintf(fid, '   ---------------------------------\n');
    fprintf(fid, '   参数      灵敏度        弹性(％)     重要性\n');
    fprintf(fid, '   ---------------------------------\n');
    for i = 1:4
        fprintf(fid, '   %-4s   %10.6f   %10.4f   %10.4f\n', ...
            results.sensitivity.param_names{i}, ...
            results.sensitivity.sensitivity(i), ...
            results.sensitivity.elasticity(i), ...
            results.sensitivity.importance(i));
    end
    fprintf(fid, '\n');
    
    fprintf(fid, '4. 未来预测 (2026-2030)\n');
    fprintf(fid, '   ------------------------------------------\n');
    fprintf(fid, '   年份      游客数(万)   冰川面积(km²)   满意度指数\n');
    fprintf(fid, '   ------------------------------------------\n');
    for i = 1:length(results.predictions.years)
        fprintf(fid, '   %4d    %10.0f    %12.1f    %12.1f\n', ...
            results.predictions.years(i), ...
            results.predictions.visitors(i)/10000, ...
            results.predictions.glacier_area(i), ...
            results.predictions.satisfaction(i));
    end
    fprintf(fid, '\n');
    
    fprintf(fid, '5. 关键发现与建议\n');
    fprintf(fid, '   ---------------------------------\n');
    fprintf(fid, '   1. 模型能够解释 %.1f%% 的居民满意度变化\n', results.performance.R2*100);
    fprintf(fid, '   2. 最重要的影响因素: 需要根据敏感性分析确定\n');
    fprintf(fid, '   3. 建议定期更新模型参数以适应环境变化\n');
    fprintf(fid, '   4. 基于模型预测制定可持续旅游政策\n');
    fclose(fid);
end