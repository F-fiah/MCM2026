%% =========================================================
%  Validation of interpolated OCV–SOC curve at 15°C
%% =========================================================

clear; clc;

%% ---------------- SOC grids ------------------------------
SOC_dense = linspace(0, 1, 400);     % smooth curve
SOC_pts   = linspace(0, 1, 18);      % discrete data points

%% ---------------- OCV parameters -------------------------
% 25°C
p25 = [ 3.679,  -0.1101, -0.2528, -6.829,  0.9386];

% 0°C
p0  = [-0.1199, -20.73,   3.588,  -0.01793, 0.7077];

OCV_fun = @(p, soc) ...
    p(1)*exp(p(2)*soc) + ...
    p(3)*exp(p(4)*soc) + ...
    p(5)*soc.^2;

%% ---------------- OCV at data temperatures ----------------
OCV_25_pts = OCV_fun(p25, SOC_pts);
OCV_0_pts  = OCV_fun(p0 , SOC_pts);

OCV_25_dense = OCV_fun(p25, SOC_dense);
OCV_0_dense  = OCV_fun(p0 , SOC_dense);

%% ---------------- Interpolation in temperature ------------
T_known = [0, 25];
T_tar   = 15;

OCV_15 = zeros(size(SOC_dense));

for i = 1:length(SOC_dense)
    OCV_i = [OCV_0_dense(i), OCV_25_dense(i)];
    OCV_15(i) = interp1(T_known, OCV_i, T_tar, 'pchip');
end

%% ---------------- Create figure ---------------------------
hFig = figure('Color','w', 'Position',[300 200 760 540]);
hold on; box on; grid on;

%% ---------------- Plot interpolated curve -----------------
h15 = plot(SOC_dense, OCV_15, ...
    'LineWidth', 2, ...
    'Color', [0 0 0]);   % elegant green

%% ---------------- Plot data points ------------------------
h25 = plot(SOC_pts, OCV_25_pts, 'o', ...
    'MarkerSize', 7, ...
    'LineWidth', 1.3, ...
    'MarkerEdgeColor', [0.00 0.45 0.74], ...
    'MarkerFaceColor', [0.00 0.45 0.74]);

h0 = plot(SOC_pts, OCV_0_pts, 's', ...
    'MarkerSize', 7, ...
    'LineWidth', 1.3, ...
    'MarkerEdgeColor', [0.85 0.33 0.10], ...
    'MarkerFaceColor', [0.85 0.33 0.10]);

%% ---------------- Axes formatting -------------------------
set(gca, ...
    'FontSize', 13, ...
    'LineWidth', 1.1, ...
    'GridAlpha', 0.25, ...
    'XMinorTick','on', ...
    'YMinorTick','on');

xlabel('State of Charge (SOC)', 'FontSize', 15, 'FontWeight','bold');
ylabel('Open-Circuit Voltage (V)', 'FontSize', 15, 'FontWeight','bold');

xlim([0 1])

%% ---------------- Legend ---------------------------------
hLeg = legend([h15 h25 h0], ...
    {'15^{\circ}C (interpolated)', ...
     '25^{\circ}C (data points)', ...
     '0^{\circ}C (data points)'}, ...
    'Location','southeast');

set(hLeg, 'FontSize', 13, 'Box','off');

%% ---------------- Title ----------------------------------
title('Validation of Interpolated OCV–SOC Curve at 15^{\circ}C', ...
    'FontSize', 16, 'FontWeight','bold');
