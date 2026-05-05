%% ========================================================================
%  Fuzzy-TOPSIS: Pressure-Driven Membrane Selection for PFAS Treatment
%  Method: Sodhi & Prabhakar (2017), arXiv:1205.5098v2
%  Implements Equations 1-15 with triangular fuzzy numbers (TFNs)
%  
%  Alternatives (4): Modified-MF, Modified-UF, NF, RO
%  Criteria (7):     C1-Long-chain rejection, C2-Short-chain rejection,
%                    C3-Water flux, C4-Fouling resistance,
%                    C5-Membrane integrity, C6-Energy efficiency,
%                    C7-Life-cycle cost-effectiveness
%  Decision Makers (3): DM1-Efficacy, DM2-Process, DM3-Sustainability
%  All criteria are BENEFIT type (higher = better)
% =========================================================================
clear; clc; close all;

%% ---- LINGUISTIC SCALE (Sodhi & Prabhakar 2017, Table I) ----
% Each linguistic term maps to a triangular fuzzy number [a, b, c]
% For Alternative Assessment:
VP = [1 1 3];   % Very Poor
P  = [1 3 5];   % Poor
F  = [3 5 7];   % Fair
G  = [5 7 9];   % Good
VG = [7 9 9];   % Very Good

% For Quality/Weight Assessment:
VL = [1 1 3];   % Very Low
L  = [1 3 5];   % Low
M  = [3 5 7];   % Medium
H  = [5 7 9];   % High
VH = [7 9 9];   % Very High

%% ---- INPUT: CRITERIA WEIGHTS BY DECISION MAKERS (Table TZ-1) ----
% Dimensions: K decision makers x n criteria, each cell is a 1x3 TFN
% Rows = DM1, DM2, DM3 | Columns = C1, C2, C3, C4, C5, C6, C7

% DM1 - Treatment-efficacy perspective
%   Prioritizes rejection (C1,C2 = VH); moderate on flux/fouling/integrity;
%   low on energy/cost (bench-scale studies don't report these)
%   Sources: Tang et al. 2006/2007; Steinle-Darling & Reinhard 2008;
%            Griffin et al. 2024; Wu et al. 2025

% DM2 - Process-engineering perspective
%   Prioritizes flux and fouling (C3,C4 = VH); high on rejection/integrity;
%   medium on energy/cost
%   Sources: Safulko et al. 2023; Liu C.J. et al. 2026; Fang et al. 2024

% DM3 - Sustainability / techno-economic perspective
%   Prioritizes energy and cost (C6,C7 = VH); high on short-chain/flux/fouling;
%   medium on long-chain/integrity
%   Sources: U.S. EPA 2024; Sgroi et al. 2025; WRF ER18-5053

K = 3;  % number of decision makers
n = 7;  % number of criteria

% Store weights as a 3D matrix: K x n x 3 (last dim = [a, b, c] of TFN)
W_ling = zeros(K, n, 3);

% DM1 weights:  C1=VH  C2=VH  C3=M   C4=M   C5=H   C6=L   C7=L
W_ling(1,1,:) = VH;
W_ling(1,2,:) = VH;
W_ling(1,3,:) = M;
W_ling(1,4,:) = M;
W_ling(1,5,:) = H;
W_ling(1,6,:) = L;
W_ling(1,7,:) = L;

% DM2 weights:  C1=H   C2=H   C3=VH  C4=VH  C5=H   C6=M   C7=M
W_ling(2,1,:) = H;
W_ling(2,2,:) = H;
W_ling(2,3,:) = VH;
W_ling(2,4,:) = VH;
W_ling(2,5,:) = H;
W_ling(2,6,:) = M;
W_ling(2,7,:) = M;

% DM3 weights:  C1=M   C2=H   C3=H   C4=H   C5=M   C6=VH  C7=VH
W_ling(3,1,:) = M;
W_ling(3,2,:) = H;
W_ling(3,3,:) = H;
W_ling(3,4,:) = H;
W_ling(3,5,:) = M;
W_ling(3,6,:) = VH;
W_ling(3,7,:) = VH;

%% ---- INPUT: ALTERNATIVE RATINGS BY DECISION MAKERS (Table TZ-2) ----
% Dimensions: m alternatives x n criteria x K decision makers x 3 (TFN)
% Justifications grounded in literature (Tables X and Y of report)

m = 4;  % number of alternatives
alt_names = {'Modified-MF', 'Modified-UF', 'NF', 'RO'};
crit_names = {'C1:Long-chain Rej', 'C2:Short-chain Rej', 'C3:Flux', ...
              'C4:Fouling Resist', 'C5:Integrity', 'C6:Energy Eff', ...
              'C7:Cost Eff'};

% Store ratings: m x n x K x 3
X_ling = zeros(m, n, K, 3);

% ---- Alternative 1: Modified-MF ----
% C1: Electro-MF reaches 70-86% (Tsai et al. 2010) = Fair
% C2: Short-chain only 50-80% PFBA (Thompson et al. 2024) = Poor to Fair
% C3: Highest flux among all classes = Very Good to Good
% C4: Indirect fouling via PFAS-induced flocs (Chen et al. 2024) = Fair to Poor
% C5: Least durable membrane class for PFAS = Poor to Fair
% C6: Lowest energy 0.1-0.5 kWh/m3 = Very Good to Good
% C7: Lowest capital cost = Good to Very Good
%           C1  C2  C3  C4  C5  C6   C7
% DM1:      F   P   VG  F   P   VG   G
X_ling(1,:,1,:) = [F; P; VG; F; P; VG; G];
% DM2:      F   F   VG  P   F   G    G
X_ling(1,:,2,:) = [F; F; VG; P; F; G; G];
% DM3:      F   P   G   F   F   VG   VG
X_ling(1,:,3,:) = [F; P; G; F; F; VG; VG];

% ---- Alternative 2: Modified-UF ----
% C1: PAA/PAH-coated UP020 = 73-78% PFOA/PFOS (Zengin et al. 2025);
%     LBL-UF = 99.90% PFOS (Liu S. et al. 2025) = Good to Fair
% C2: LBL-UF = 99.24-99.61% PFBA (Liu S. et al. 2025) = Fair
% C3: High flux, lower than MF = Very Good to Good
% C4: Similar to MF, slightly better = Fair
% C5: Better than MF due to thicker support = Fair
% C6: Low energy 0.1-0.5 kWh/m3 = Very Good to Good
% C7: Low-moderate cost = Good
%           C1  C2  C3  C4  C5  C6   C7
% DM1:      G   F   VG  F   F   VG   G
X_ling(2,:,1,:) = [G; F; VG; F; F; VG; G];
% DM2:      F   F   G   F   F   G    G
X_ling(2,:,2,:) = [F; F; G; F; F; G; G];
% DM3:      F   F   G   F   F   G    G
X_ling(2,:,3,:) = [F; F; G; F; F; G; G];

% ---- Alternative 3: NF ----
% C1: NF270 >95-99%; NF90 >97% all PFAAs (Griffin et al. 2024) = Very Good to Good
% C2: NF270 PFPeA 72% (Steinle-Darling 2008); NF90 TFMS 97.6% = Good to Fair
% C3: 15-70 LMH, moderate (Ochando-Pulido et al. 2018) = Good to Fair
% C4: Most affected by NOM fouling (Deringer 2024) = Fair to Poor
% C5: Polyamide robust but PFAS adsorption occurs = Good
% C6: 0.14-2.8 kWh/m3 (Hasan et al. 2025) = Fair
% C7: CAPEX $0.40-0.51/m3 (EPA 2024) = Fair
%           C1  C2  C3  C4  C5  C6  C7
% DM1:      VG  G   G   F   G   F   F
X_ling(3,:,1,:) = [VG; G; G; F; G; F; F];
% DM2:      G   G   F   P   G   F   F
X_ling(3,:,2,:) = [G; G; F; P; G; F; F];
% DM3:      G   F   F   F   G   F   F
X_ling(3,:,3,:) = [G; F; F; F; G; F; F];

% ---- Alternative 4: RO ----
% C1: >99% PFOS across 0.5-1500 mg/L (Tang et al. 2006) = Very Good
% C2: PFHxA up to 95%; PFBA/PFPeA 70-95% (Li et al. 2020) = Very Good to Good
% C3: 10-15 LMH, lowest flux (Ochando-Pulido et al. 2018) = Fair to Poor
% C4: Dense layer resists cake penetration, scaling risk = Good to Fair
% C5: Most robust membrane integrity = Very Good to Good
% C6: Highest energy 2-6 kWh/m3 = Poor
% C7: Highest CAPEX + concentrate management = Poor to Fair
%           C1  C2  C3  C4  C5   C6  C7
% DM1:      VG  VG  F   G   VG   P   P
X_ling(4,:,1,:) = [VG; VG; F; G; VG; P; P];
% DM2:      VG  VG  P   F   G    P   P
X_ling(4,:,2,:) = [VG; VG; P; F; G; P; P];
% DM3:      G   G   P   G   G    P   F
X_ling(4,:,3,:) = [G; G; P; G; G; P; F];

%% ========================================================================
%  STEP 1: AGGREGATE FUZZY WEIGHTS AND RATINGS (Equations 3 & 4)
% =========================================================================
fprintf('============================================================\n');
fprintf('  STEP 1: Aggregate Weights (Eq.4) and Ratings (Eq.3)\n');
fprintf('============================================================\n\n');

% ---- Aggregate weights w_j = (a'_j, b'_j, c'_j) ----
% Equation 4: a' = min_k{a'k}, b' = (1/K)*sum(b'k), c' = max_k{c'k}
w_agg = zeros(n, 3);  % n criteria x 3 (TFN components)
for j = 1:n
    w_agg(j,1) = min(W_ling(:,j,1));         % a' = min of all DMs' a
    w_agg(j,2) = mean(W_ling(:,j,2));        % b' = mean of all DMs' b
    w_agg(j,3) = max(W_ling(:,j,3));         % c' = max of all DMs' c
end

fprintf('Aggregated Fuzzy Weights w_j:\n');
fprintf('%-25s  (%5.2f, %5.2f, %5.2f)\n', ...
    'Criterion', nan, nan, nan);  % header placeholder
for j = 1:n
    fprintf('  %-23s  (%5.2f, %5.2f, %5.2f)\n', ...
        crit_names{j}, w_agg(j,1), w_agg(j,2), w_agg(j,3));
end

% ---- Sample calculation for C1 ----
fprintf('\n--- Sample Calculation (C1 weight, Eq.4) ---\n');
fprintf('  DM1: VH = (7, 9, 9)\n');
fprintf('  DM2: H  = (5, 7, 9)\n');
fprintf('  DM3: M  = (3, 5, 7)\n');
fprintf('  a'' = min{7, 5, 3} = %.0f\n', w_agg(1,1));
fprintf('  b'' = (9+7+5)/3   = %.4f\n', w_agg(1,2));
fprintf('  c'' = max{9, 9, 7} = %.0f\n', w_agg(1,3));
fprintf('  => w_1 = (%.2f, %.4f, %.2f)\n\n', w_agg(1,:));

% ---- Aggregate ratings x_ij = (a_ij, b_ij, c_ij) ----
% Equation 3: a = min_k{a_k}, b = (1/K)*sum(b_k), c = max_k{c_k}
x_agg = zeros(m, n, 3);  % m alternatives x n criteria x 3 (TFN)
for i = 1:m
    for j = 1:n
        x_agg(i,j,1) = min(X_ling(i,j,:,1));     % a = min across DMs
        x_agg(i,j,2) = mean(X_ling(i,j,:,2));    % b = mean across DMs
        x_agg(i,j,3) = max(X_ling(i,j,:,3));     % c = max across DMs
    end
end

fprintf('Aggregated Fuzzy Decision Matrix x_ij:\n');
for i = 1:m
    fprintf('  %s:\n', alt_names{i});
    for j = 1:n
        fprintf('    %-23s  (%5.2f, %5.2f, %5.2f)\n', ...
            crit_names{j}, x_agg(i,j,1), x_agg(i,j,2), x_agg(i,j,3));
    end
end

% ---- Sample calculation for MF on C1 ----
fprintf('\n--- Sample Calculation (MF rating on C1, Eq.3) ---\n');
fprintf('  DM1: F = (3, 5, 7)\n');
fprintf('  DM2: F = (3, 5, 7)\n');
fprintf('  DM3: F = (3, 5, 7)\n');
fprintf('  a = min{3,3,3} = %.0f\n', x_agg(1,1,1));
fprintf('  b = (5+5+5)/3  = %.4f\n', x_agg(1,1,2));
fprintf('  c = max{7,7,7} = %.0f\n', x_agg(1,1,3));
fprintf('  => x_{MF,C1} = (%.2f, %.4f, %.2f)\n\n', ...
    x_agg(1,1,1), x_agg(1,1,2), x_agg(1,1,3));

%% ========================================================================
%  STEP 2: NORMALIZED FUZZY DECISION MATRIX (Equations 7 & 8)
% =========================================================================
fprintf('============================================================\n');
fprintf('  STEP 2: Normalized Fuzzy Decision Matrix (Eq.8)\n');
fprintf('============================================================\n\n');

% All criteria are BENEFIT type, so use Equation 8:
%   r_ij = (a_ij / c*_j,  b_ij / c*_j,  c_ij / c*_j)
%   where c*_j = max_i {c_ij}

% Compute c*_j for each criterion
c_star = zeros(1, n);
for j = 1:n
    c_star(j) = max(x_agg(:,j,3));  % max of c-component across all alternatives
end

fprintf('c*_j (max c per criterion):\n  ');
fprintf('%.2f  ', c_star);
fprintf('\n\n');

% Normalize
r_norm = zeros(m, n, 3);
for i = 1:m
    for j = 1:n
        r_norm(i,j,1) = x_agg(i,j,1) / c_star(j);
        r_norm(i,j,2) = x_agg(i,j,2) / c_star(j);
        r_norm(i,j,3) = x_agg(i,j,3) / c_star(j);
    end
end

fprintf('Normalized Fuzzy Decision Matrix r_ij:\n');
for i = 1:m
    fprintf('  %s:\n', alt_names{i});
    for j = 1:n
        fprintf('    %-23s  (%6.4f, %6.4f, %6.4f)\n', ...
            crit_names{j}, r_norm(i,j,1), r_norm(i,j,2), r_norm(i,j,3));
    end
end

% ---- Sample calculation for MF on C1 ----
fprintf('\n--- Sample Calculation (MF on C1, Eq.8) ---\n');
fprintf('  x_{MF,C1} = (3, 5, 7)\n');
fprintf('  c*_1 = max{7, 9, 9, 9} = %.0f\n', c_star(1));
fprintf('  r_{MF,C1} = (3/9, 5/9, 7/9) = (%.4f, %.4f, %.4f)\n\n', ...
    r_norm(1,1,1), r_norm(1,1,2), r_norm(1,1,3));

%% ========================================================================
%  STEP 3: WEIGHTED NORMALIZED FUZZY DECISION MATRIX (Equation 10)
% =========================================================================
fprintf('============================================================\n');
fprintf('  STEP 3: Weighted Normalized Matrix (Eq.10)\n');
fprintf('============================================================\n\n');

% v_ij = r_ij (.) w_j  — component-wise multiplication of TFNs
% v_ij = (r_a * w_a,  r_b * w_b,  r_c * w_c)
v_weighted = zeros(m, n, 3);
for i = 1:m
    for j = 1:n
        v_weighted(i,j,1) = r_norm(i,j,1) * w_agg(j,1);
        v_weighted(i,j,2) = r_norm(i,j,2) * w_agg(j,2);
        v_weighted(i,j,3) = r_norm(i,j,3) * w_agg(j,3);
    end
end

fprintf('Weighted Normalized Fuzzy Decision Matrix v_ij:\n');
for i = 1:m
    fprintf('  %s:\n', alt_names{i});
    for j = 1:n
        fprintf('    %-23s  (%6.3f, %6.3f, %6.3f)\n', ...
            crit_names{j}, v_weighted(i,j,1), v_weighted(i,j,2), v_weighted(i,j,3));
    end
end

% ---- Sample calculation for MF on C1 ----
fprintf('\n--- Sample Calculation (MF on C1, Eq.10) ---\n');
fprintf('  r_{MF,C1} = (%.4f, %.4f, %.4f)\n', ...
    r_norm(1,1,1), r_norm(1,1,2), r_norm(1,1,3));
fprintf('  w_1       = (%.2f, %.4f, %.2f)\n', w_agg(1,:));
fprintf('  v_{MF,C1} = (%.4f x %.2f, %.4f x %.4f, %.4f x %.2f)\n', ...
    r_norm(1,1,1), w_agg(1,1), r_norm(1,1,2), w_agg(1,2), ...
    r_norm(1,1,3), w_agg(1,3));
fprintf('            = (%.3f, %.3f, %.3f)\n\n', ...
    v_weighted(1,1,1), v_weighted(1,1,2), v_weighted(1,1,3));

%% ========================================================================
%  STEP 4: FPIS, FNIS, AND DISTANCES (Equations 11-14)
% =========================================================================
fprintf('============================================================\n');
fprintf('  STEP 4: FPIS, FNIS, and Distances (Eq.11-14)\n');
fprintf('============================================================\n\n');

% ---- FPIS: A* = (v*_1, ..., v*_n) where v*_j = (c, c, c) ----
% Equation 11: c = max_i {c''_ij}
FPIS = zeros(1, n);
for j = 1:n
    FPIS(j) = max(v_weighted(:,j,3));  % max of c-component across alternatives
end

% ---- FNIS: A- = (v-_1, ..., v-_n) where v-_j = (a, a, a) ----
% Equation 12: a = min_i {a''_ij}
FNIS = zeros(1, n);
for j = 1:n
    FNIS(j) = min(v_weighted(:,j,1));  % min of a-component across alternatives
end

fprintf('FPIS (A*) - v*_j = (c*, c*, c*) for each criterion:\n  ');
fprintf('%.3f  ', FPIS);
fprintf('\n');
fprintf('FNIS (A-) - v-_j = (a-, a-, a-) for each criterion:\n  ');
fprintf('%.3f  ', FNIS);
fprintf('\n\n');

% ---- Vertex distance function (Equation 2) ----
% d(a_tilde, b_tilde) = sqrt( (1/3) * [(a-a')^2 + (b-b')^2 + (c-c')^2] )
vertex_dist = @(tfn, ideal) sqrt((1/3) * ...
    ((tfn(1)-ideal)^2 + (tfn(2)-ideal)^2 + (tfn(3)-ideal)^2));

% ---- Distance to FPIS (Equation 13) ----
d_star = zeros(m, n);      % per-criterion distances
D_star = zeros(m, 1);      % total distance per alternative
for i = 1:m
    for j = 1:n
        tfn_ij = squeeze(v_weighted(i,j,:))';
        d_star(i,j) = vertex_dist(tfn_ij, FPIS(j));
    end
    D_star(i) = sum(d_star(i,:));  % Equation 13: sum across criteria
end

% ---- Distance to FNIS (Equation 14) ----
d_minus = zeros(m, n);     % per-criterion distances
D_minus = zeros(m, 1);     % total distance per alternative
for i = 1:m
    for j = 1:n
        tfn_ij = squeeze(v_weighted(i,j,:))';
        d_minus(i,j) = vertex_dist(tfn_ij, FNIS(j));
    end
    D_minus(i) = sum(d_minus(i,:));  % Equation 14: sum across criteria
end

% ---- Display distance tables ----
fprintf('Per-criterion distances to FPIS:\n');
fprintf('%-15s', 'Alternative');
for j = 1:n
    fprintf('  %-8s', crit_names{j}(1:min(8,end)));
end
fprintf('  %-8s\n', 'SUM d*_i');
for i = 1:m
    fprintf('%-15s', alt_names{i});
    for j = 1:n
        fprintf('  %8.3f', d_star(i,j));
    end
    fprintf('  %8.3f\n', D_star(i));
end

fprintf('\nPer-criterion distances to FNIS:\n');
fprintf('%-15s', 'Alternative');
for j = 1:n
    fprintf('  %-8s', crit_names{j}(1:min(8,end)));
end
fprintf('  %-8s\n', 'SUM d-_i');
for i = 1:m
    fprintf('%-15s', alt_names{i});
    for j = 1:n
        fprintf('  %8.3f', d_minus(i,j));
    end
    fprintf('  %8.3f\n', D_minus(i));
end

% ---- Sample calculation for MF on C1 ----
fprintf('\n--- Sample Calculation (MF distance to FPIS on C1, Eq.2 & 13) ---\n');
fprintf('  v_{MF,C1} = (%.3f, %.3f, %.3f)\n', v_weighted(1,1,:));
fprintf('  FPIS_C1   = (%.3f, %.3f, %.3f)  [i.e., (c*, c*, c*)]\n', ...
    FPIS(1), FPIS(1), FPIS(1));
fprintf('  d_v = sqrt( (1/3) * [(%.3f-%.3f)^2 + (%.3f-%.3f)^2 + (%.3f-%.3f)^2] )\n', ...
    v_weighted(1,1,1), FPIS(1), v_weighted(1,1,2), FPIS(1), ...
    v_weighted(1,1,3), FPIS(1));
term1 = (v_weighted(1,1,1) - FPIS(1))^2;
term2 = (v_weighted(1,1,2) - FPIS(1))^2;
term3 = (v_weighted(1,1,3) - FPIS(1))^2;
fprintf('     = sqrt( (1/3) * [%.3f + %.3f + %.3f] )\n', term1, term2, term3);
fprintf('     = sqrt( (1/3) * %.3f )\n', term1+term2+term3);
fprintf('     = sqrt( %.3f )\n', (term1+term2+term3)/3);
fprintf('     = %.3f\n\n', d_star(1,1));

%% ========================================================================
%  STEP 5: CLOSENESS COEFFICIENT AND RANKING (Equation 15)
% =========================================================================
fprintf('============================================================\n');
fprintf('  STEP 5: Closeness Coefficient & Ranking (Eq.15)\n');
fprintf('============================================================\n\n');

% CC_i = d-_i / (d-_i + d*_i)
CC = D_minus ./ (D_minus + D_star);

% Rank (descending CC = better)
[CC_sorted, rank_idx] = sort(CC, 'descend');

% ---- Display results ----
fprintf('%-15s  %10s  %10s  %10s  %4s\n', ...
    'Alternative', 'd*_i', 'd-_i', 'CC_i', 'Rank');
fprintf('%s\n', repmat('-', 1, 55));
for r = 1:m
    i = rank_idx(r);
    fprintf('%-15s  %10.3f  %10.3f  %10.4f  %4d\n', ...
        alt_names{i}, D_star(i), D_minus(i), CC(i), r);
end

% ---- Sample calculation for MF ----
fprintf('\n--- Sample Calculation (MF closeness coefficient, Eq.15) ---\n');
fprintf('  d*_{MF}  = %.3f\n', D_star(1));
fprintf('  d-_{MF}  = %.3f\n', D_minus(1));
fprintf('  CC_{MF}  = %.3f / (%.3f + %.3f)\n', D_minus(1), D_minus(1), D_star(1));
fprintf('           = %.3f / %.3f\n', D_minus(1), D_minus(1)+D_star(1));
fprintf('           = %.4f\n\n', CC(1));

%% ========================================================================
%  VISUALIZATION
% =========================================================================
fprintf('============================================================\n');
fprintf('  GENERATING FIGURES\n');
fprintf('============================================================\n\n');

% ---- Figure 1: Closeness Coefficients Bar Chart ----
figure('Position', [100 100 700 450]);
bar_data = CC(rank_idx);
b = bar(bar_data, 0.6, 'FaceColor', 'flat');

% Color gradient: best = dark green, worst = light gray
colors = [0.13 0.55 0.13;   % rank 1: forest green
          0.20 0.60 0.40;   % rank 2: green
          0.40 0.65 0.80;   % rank 3: steel blue
          0.75 0.75 0.75];  % rank 4: gray
b.CData = colors;

set(gca, 'XTickLabel', alt_names(rank_idx), 'FontSize', 12, 'FontName', 'Calibri');
ylabel('Closeness Coefficient (CC_i)', 'FontSize', 13);
title('Fuzzy-TOPSIS Ranking: Membrane Alternatives for PFAS Treatment', ...
    'FontSize', 14, 'FontWeight', 'bold');

% Add value labels on bars
for r = 1:m
    text(r, bar_data(r) + 0.005, sprintf('%.4f', bar_data(r)), ...
        'HorizontalAlignment', 'center', 'FontSize', 11, 'FontWeight', 'bold');
end

% Add rank labels
for r = 1:m
    text(r, 0.02, sprintf('Rank %d', r), ...
        'HorizontalAlignment', 'center', 'FontSize', 10, 'Color', 'w', ...
        'FontWeight', 'bold');
end

ylim([0, max(CC)*1.15]);
grid on;
set(gca, 'GridAlpha', 0.3);

%% ---- Figure 2: Radar/Spider Chart of Normalized Performance ----
%figure('Position', [100 100 700 600]);

% Use the normalized aggregated ratings (r_norm, b-component) for the radar
%radar_data = zeros(m, n);
%for i = 1:m
    %for j = 1:n
        %radar_data(i,j) = r_norm(i,j,2);  % use the 'b' (most probable) value
    %end
%end

% Spider chart using polar coordinates
% angles = linspace(0, 2*pi, n+1);
% angles = angles(1:end-1);

% Shorter labels for radar plot
% radar_labels = {'Long-chain', 'Short-chain', 'Flux', 'Fouling', ...
%                 'Integrity', 'Energy', 'Cost'};
% 
% alt_colors = [0.85 0.33 0.10;   % MF: orange
%               0.00 0.45 0.74;   % UF: blue
%               0.47 0.67 0.19;   % NF: green
%               0.64 0.08 0.18];  % RO: dark red
% 
% hold on;
% for i = 1:m
%     vals = [radar_data(i,:), radar_data(i,1)];  % close the polygon
%     angs = [angles, angles(1)];
%     polarplot(angs, vals, '-o', 'LineWidth', 2, 'Color', alt_colors(i,:), ...
%         'MarkerSize', 6, 'MarkerFaceColor', alt_colors(i,:));
% end
% hold off;
% 
% % Configure polar axes
% ax = gca;
% ax.ThetaTick = rad2deg(angles);
% ax.ThetaTickLabel = radar_labels;
% ax.RLim = [0 1];
% ax.FontSize = 11;
% ax.FontName = 'Calibri';
% 
% legend(alt_names, 'Location', 'southoutside', 'Orientation', 'horizontal', ...
%     'FontSize', 11);
% title('Normalized Performance Profile (b-component of TFN)', ...
%     'FontSize', 14, 'FontWeight', 'bold');

% ---- Figure 3: Distance Comparison ----
figure('Position', [100 100 700 450]);
dist_data = [D_star(rank_idx), D_minus(rank_idx)];
b2 = bar(dist_data, 'grouped');
b2(1).FaceColor = [0.85 0.33 0.10];  % d* = orange
b2(2).FaceColor = [0.00 0.45 0.74];  % d- = blue

set(gca, 'XTickLabel', alt_names(rank_idx), 'FontSize', 12, 'FontName', 'Calibri');
ylabel('Total Distance', 'FontSize', 13);
title('Distance to FPIS (d*) and FNIS (d^-) by Alternative', ...
    'FontSize', 14, 'FontWeight', 'bold');
legend({'d*_i (to FPIS)', 'd^-_i (to FNIS)'}, 'Location', 'northeast', ...
    'FontSize', 10);
grid on;
set(gca, 'GridAlpha', 0.3);

fprintf('Figures generated successfully.\n');
fprintf('============================================================\n');
fprintf('  ANALYSIS COMPLETE\n');
fprintf('  Best alternative: %s (CC = %.4f)\n', alt_names{rank_idx(1)}, CC(rank_idx(1)));
fprintf('============================================================\n');

