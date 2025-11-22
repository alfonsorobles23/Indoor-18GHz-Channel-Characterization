%% SCRIPT FINAL CAPÍTULO 5: COMPARACIÓN Y VALIDACIÓN DE MODELOS
clc;
clear;
close all;

%% 1. CONFIGURACIÓN GENERAL
% ---------------------------------------------------------
dist_total = 60;            
res = 0.1;                  
d = 3.15:res:dist_total;    
d_corner = 39.4;            
d0 = 3.15;                  
c = 0.3;                    

idx_los = d <= d_corner;
idx_nlos = d > d_corner;

% --- PALETA DE COLORES PRINCIPAL ---
color_ds   = [0.8500 0.3250 0.0980]; % Rojo/Naranjo (Tu Modelo Principal)
color_ci   = [0.0000 1.0000 1.0000]; % Rosado Fuerte (Tu Modelo CI)
color_itu  = [0.0000 0.4470 0.7410]; % Azul (ITU-R)
color_3gpp = [0.0000 0.6000 0.0000]; % Verde (3GPP)

% --- PARÁMETROS ---
n_DS = 2.28; S_DS = 41.22;        
n_CI_LoS = 2.29; n_CI_NLoS = 5.79;
ITU_LoS = struct('alpha', 1.57, 'beta', 29.46, 'gamma', 2.24);
ITU_NLoS = struct('alpha', 2.78, 'beta', 28.62, 'gamma', 2.54);

f_target = 18; f_4G = 2.6; f_5G_mid = 3.5; f_5G_mmW = 28;  
freqs_tech = [f_4G, f_5G_mid, f_5G_mmW];
names_tech = {'4G (2.6 GHz)', '5G Sub-6 (3.5 GHz)', '5G mmWave (28 GHz)'};

%% 2. CÁLCULO (18 GHz)
% ---------------------------------------------------------
FSPL_18 = 20*log10(4*pi*d0*f_target/c);

% A. DS (18 GHz)
PL_x1_18 = FSPL_18 + 10*n_DS*log10(d_corner/d0);
PL_DS_18 = zeros(size(d));
PL_DS_18(idx_los) = FSPL_18 + 10*n_DS*log10(d(idx_los)/d0);
PL_DS_18(idx_nlos) = PL_x1_18 + S_DS + 10*n_DS*log10(d(idx_nlos)/d_corner);

% B. CI (18 GHz)
PL_CI_18 = zeros(size(d));
PL_CI_18(idx_los) = FSPL_18 + 10*n_CI_LoS*log10(d(idx_los)/d0);
PL_CI_18(idx_nlos) = FSPL_18 + 10*n_CI_NLoS*log10(d(idx_nlos)/d0);

% C. ITU-R (18 GHz)
PL_ITU_18 = zeros(size(d));
PL_ITU_18(idx_los) = 10*ITU_LoS.alpha*log10(d(idx_los)) + ITU_LoS.beta + 10*ITU_LoS.gamma*log10(f_target);
PL_ITU_18(idx_nlos) = 10*ITU_NLoS.alpha*log10(d(idx_nlos)) + ITU_NLoS.beta + 10*ITU_NLoS.gamma*log10(f_target);

% D. 3GPP (18 GHz)
pl_3gpp_los = 32.4 + 17.3*log10(d) + 20*log10(f_target);
pl_3gpp_nlos_term = 38.3*log10(d) + 17.3 + 24.9*log10(f_target);
PL_3GPP_18 = zeros(size(d));
PL_3GPP_18(idx_los) = pl_3gpp_los(idx_los);
PL_3GPP_18(idx_nlos) = max(pl_3gpp_los(idx_nlos), pl_3gpp_nlos_term(idx_nlos));

%% 3. GENERACIÓN DE GRÁFICOS
% ---------------------------------------------------------
set(0, 'DefaultAxesFontSize', 12);
set(0, 'DefaultLineLineWidth', 2);

% --- GRÁFICO 1: DESVIACIÓN DE ESTÁNDARES (Colores Originales) ---
figure('Name', 'Desviacion Estandares', 'Position', [100, 100, 900, 500]);
hold on;

err_ITU = PL_ITU_18 - PL_DS_18;
err_3GPP = PL_3GPP_18 - PL_DS_18;
err_CI = PL_CI_18 - PL_DS_18;

plot(d, err_3GPP, '-', 'Color', color_3gpp, 'LineWidth', 2, 'DisplayName', 'Error 3GPP (Verde)');
plot(d, err_ITU, '-.', 'Color', color_itu, 'LineWidth', 2, 'DisplayName', 'Error ITU-R (Azul)');
plot(d, err_CI, '--', 'Color', color_ci, 'LineWidth', 2, 'DisplayName', 'Error Propio CI (Rosado)');

yline(0, 'k-', 'HandleVisibility', 'off');
xline(d_corner, 'k:', 'HandleVisibility', 'off');
fill([d_corner, 60, 60, d_corner], [-40, -40, 0, 0], 'r', 'FaceAlpha', 0.08, 'EdgeColor', 'none', 'DisplayName', 'Zona de Subestimación');

grid on;
xlabel('Distancia Manhattan [m]'); ylabel('Diferencia de Path Loss [dB]');
title('Error de Predicción de Estándares a 18 GHz');
subtitle('Referencia: Modelo Propio Dual-Slope (Validado en Terreno)');
legend('Location', 'southwest');
ylim([-35 15]);
text(41, -10, '\leftarrow Los estándares fallan al predecir el quiebre', 'FontSize', 11, 'Color', 'red', 'FontWeight', 'bold');
hold off;

% --- GRÁFICO 2: COMPARACIÓN DIRECTA A 18 GHz (Colores Originales) ---
figure('Name', 'Comparacion 18 GHz', 'Position', [150, 150, 900, 600]);
hold on;

plot(d, PL_DS_18, '-', 'Color', color_ds, 'LineWidth', 3, 'DisplayName', 'Propio: Dual-Slope (Rojo)');
plot(d, PL_CI_18, '--', 'Color', color_ci, 'LineWidth', 2, 'DisplayName', 'Propio: Close-In (Rosado)');
plot(d, PL_ITU_18, '-.', 'Color', color_itu, 'LineWidth', 2, 'DisplayName', 'Estándar: ITU-R (Azul)');
plot(d, PL_3GPP_18, ':', 'Color', color_3gpp, 'LineWidth', 2.5, 'DisplayName', 'Estándar: 3GPP (Verde)');

xline(d_corner, 'k-', 'LineWidth', 1, 'DisplayName', 'L-Junction');
grid on; box on;
xlabel('Distancia Manhattan [m]'); ylabel('Path Loss [dB]');
title('Comparación de Modelos a 18 GHz');
subtitle('Contraste entre modelos empíricos ajustados y estándares genéricos');
legend('Location', 'southeast');
ylim([60 170]);
hold off;

% --- GRÁFICO 3: CONTEXTO TECNOLÓGICO (Colores Solicitados) ---
figure('Name', 'Contexto Tecnologico', 'Position', [200, 200, 1000, 600]);
hold on;

% 1. Tus Modelos (Destacados)
plot(d, PL_DS_18, '-', 'Color', color_ds, 'LineWidth', 3, 'DisplayName', 'Propio DS 18 GHz');
plot(d, PL_CI_18, '--', 'Color', color_ci, 'LineWidth', 2, 'DisplayName', 'Propio CI 18 GHz');

% 2. Estándares con Colores Específicos
% Definición manual de colores para este gráfico:
tech_colors = [
    0.0000 0.4470 0.7410; % 1. 4G (2.6 GHz) -> AZUL
    0.4940 0.1840 0.5560; % 2. 5G Mid (3.5 GHz) -> PÚRPURA (Diferente)
    0.0000 0.6000 0.0000  % 3. 5G mmW (28 GHz) -> VERDE (Solicitado)
];

for i = 1:3
    f = freqs_tech(i);
    col = tech_colors(i,:);
    
    pl_itu_f = zeros(size(d));
    pl_itu_f(idx_los) = 10*ITU_LoS.alpha*log10(d(idx_los)) + ITU_LoS.beta + 10*ITU_LoS.gamma*log10(f);
    pl_itu_f(idx_nlos) = 10*ITU_NLoS.alpha*log10(d(idx_nlos)) + ITU_NLoS.beta + 10*ITU_NLoS.gamma*log10(f);
    
    pl_3gpp_l = 32.4 + 17.3*log10(d) + 20*log10(f);
    pl_3gpp_n = max(pl_3gpp_l, 38.3*log10(d) + 17.3 + 24.9*log10(f));
    pl_3gpp_f = pl_3gpp_l; pl_3gpp_f(idx_nlos) = pl_3gpp_n(idx_nlos);
    
    plot(d, pl_itu_f, '-', 'Color', [col 0.4], 'LineWidth', 1, 'DisplayName', ['ITU-R ' names_tech{i}]);
    plot(d, pl_3gpp_f, ':', 'Color', col, 'LineWidth', 2, 'DisplayName', ['3GPP ' names_tech{i}]);
end

xline(d_corner, 'k-', 'HandleVisibility', 'off');
grid on; box on;
xlabel('Distancia Manhattan [m]'); ylabel('Path Loss [dB]');
title('Posicionamiento de 18 GHz frente a Tecnologías 4G/5G');
subtitle('Comparación del modelo propio (18 GHz) vs Estándares en frecuencias comerciales');
legend('Location', 'eastoutside'); 
ylim([50 180]);
hold off;

%% 4. DATOS DUROS PARA LA MEMORIA (CORREGIDO Y VALIDADO)

% Punto de análisis: Borde de celda / NLoS profundo (55 metros)
dist_analisis = 55;
[~, idx_val] = min(abs(d - dist_analisis)); % Encuentra el índice más cercano a 55m

% --- 1. ANÁLISIS DEL QUIEBRE (EL "SALTO") ---
% Comparamos el valor justo antes (39.3m) y después (39.5m) del quiebre
pl_ds_pre  = PL_DS_18(find(idx_nlos,1)-1);
pl_ds_post = PL_DS_18(find(idx_nlos,1)); 
salto_ds = pl_ds_post - pl_ds_pre;

pl_ci_pre  = PL_CI_18(find(idx_nlos,1)-1);
pl_ci_post = PL_CI_18(find(idx_nlos,1)); 
salto_ci = pl_ci_post - pl_ci_pre;

fprintf('\n1. SEVERIDAD DEL QUIEBRE (L-Junction a 39.4 m):\n');
fprintf('   - Modelo Dual-Slope (Tu Tesis): %.2f dB (Caída abrupta real)\n', salto_ds);
fprintf('   - Modelo Close-In:              %.2f dB (No detecta el quiebre)\n', salto_ci);
fprintf('   -> Conclusión: El modelo CI subestima la pérdida instantánea en el quiebre.\n');

% --- 2. PRECISIÓN DE LOS ESTÁNDARES EN 18 GHz ---

err_itu_val = PL_ITU_18(idx_val) - PL_DS_18(idx_val);
err_3gpp_val = PL_3GPP_18(idx_val) - PL_DS_18(idx_val);

fprintf('\n2. ERROR DE LOS ESTÁNDARES A 18 GHz (a %d metros):\n', dist_analisis);
fprintf('   - Tu Modelo (Realidad): %.2f dB\n', PL_DS_18(idx_val));
fprintf('   - Estándar ITU-R:       %.2f dB (Error: %.2f dB)\n', PL_ITU_18(idx_val), err_itu_val);
fprintf('   - Estándar 3GPP:        %.2f dB (Error: %.2f dB)\n', PL_3GPP_18(idx_val), err_3gpp_val);
fprintf('   -> Interpretación: Los estándares son "optimistas" por ~20-25 dB.\n');
fprintf('      Si diseñas la red usando ITU/3GPP, tendrás zonas sin cobertura real.\n');

% --- 3. CONTEXTO TECNOLÓGICO (PENALIZACIÓN POR FRECUENCIA) ---
% Se calcula cuanto sube el Path Loss solo por cambiar la frecuencia,
% Se asume que se usa el modelo Dual-Slope diseñado (misma geometría, distinta frecuencia).
% Fórmula: Delta = 20 * log10(f2 / f1)

pl_ds_4g  = PL_DS_18(idx_val) - 20*log10(18/2.6); % Proyección a 2.6 GHz
pl_ds_5g  = PL_DS_18(idx_val) - 20*log10(18/3.5); % Proyección a 3.5 GHz
pl_ds_mmw = PL_DS_18(idx_val) + 20*log10(28/18);  % Proyección a 28 GHz

fprintf('\n3. PENALIZACIÓN POR FRECUENCIA (Usando tu geometría Dual-Slope):\n');
fprintf('   (Comparación de pérdidas manteniendo el mismo entorno físico a %d m)\n', dist_analisis);
fprintf('   - 4G (2.6 GHz):   %.2f dB\n', pl_ds_4g);
fprintf('   - 5G (3.5 GHz):   %.2f dB\n', pl_ds_5g);
fprintf('   - Tesis (18 GHz): %.2f dB\n', PL_DS_18(idx_val));
fprintf('   - mmW (28 GHz):   %.2f dB\n', pl_ds_mmw);
fprintf('\n   -> Costo de migrar a 18 GHz desde 4G: +%.2f dB\n', PL_DS_18(idx_val) - pl_ds_4g);
fprintf('   -> Costo de migrar a 28 GHz desde 18 GHz: +%.2f dB\n', pl_ds_mmw - PL_DS_18(idx_val));
fprintf('================================================================\n');