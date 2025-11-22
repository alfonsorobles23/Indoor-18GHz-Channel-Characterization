% SCRIPT PARA OPTIMIZAR EL MODELO DE QUIEBRE (DUAL-SLOPE)
% USANDO DATOS DE MÚLTIPLES ALTURAS Y ANCLAJE FSPL EN d0
clc;
clear;
close all;

% --- 1. Configuración del Sistema y Carga de Datos (Estilo CI) ---
fprintf('Cargando datos de medición para las alturas seleccionadas...\n');
f = 18e9; % Frecuencia de la señal en Hz (18 GHz)
c = 3e8;  % Velocidad de la luz en m/s
lambda = c / f; % Longitud de onda

% Alturas de la antena receptora y archivos correspondientes
alturas = [0.61, 1.30, 1.91]; % Alturas de la antena receptora en m
archivos = {'resultados_metodo_lee061.mat', ...
            'resultados_metodo_lee130.mat', ...
            'resultados_metodo_lee191.mat'};

% Pre-asignación de memoria (basada en el primer archivo)
try
    temp_data = load(archivos{1});
catch
    error('No se pudo encontrar el archivo de datos base: %s', archivos{1});
end
n_los_points_aprox = length(temp_data.distancias_los);
n_nlos_points_aprox = length(temp_data.distancias_nlos);
total_files = length(archivos);

% Pre-asignación más generosa
dist_total_los = zeros(n_los_points_aprox * total_files, 1);
pl_medido_los = zeros(n_los_points_aprox * total_files, 1);
dist_total_nlos = zeros(n_nlos_points_aprox * total_files, 1);
pl_medido_nlos = zeros(n_nlos_points_aprox * total_files, 1);

los_idx = 1;
nlos_idx = 1;

for i = 1:total_files
    try
        datos = load(archivos{i});
        fprintf('Archivo "%s" cargado para h_r = %.2f m.\n', archivos{i}, alturas(i));
        
        % Índices para LOS
        los_end_idx = los_idx + length(datos.distancias_los) - 1;
        dist_total_los(los_idx:los_end_idx) = datos.distancias_los;
        pl_medido_los(los_idx:los_end_idx) = datos.pl_lee_los;
        los_idx = los_end_idx + 1;
        
        % Índices para NLOS
        nlos_end_idx = nlos_idx + length(datos.distancias_nlos) - 1;
        dist_total_nlos(nlos_idx:nlos_end_idx) = datos.distancias_nlos;
        pl_medido_nlos(nlos_idx:nlos_end_idx) = datos.pl_lee_nlos;
        nlos_idx = nlos_end_idx + 1;
        
    catch
        warning('Archivo "%s" no encontrado. Saltando a la siguiente altura.', archivos{i});
    end
end

% Recortar los vectores al tamaño real de los datos cargados
dist_total_los = dist_total_los(1:los_idx-1);
pl_medido_los = pl_medido_los(1:los_idx-1);
dist_total_nlos = dist_total_nlos(1:nlos_idx-1);
pl_medido_nlos = pl_medido_nlos(1:nlos_idx-1);

dist_total_global = [dist_total_los; dist_total_nlos];

% --- 2. Optimización Conjunta de Parámetros del Modelo de Quiebre ---
fprintf('\nIniciando optimización conjunta para encontrar n y S...\n');

% Anclaje físico basado en d0 = 3.15 m y su FSPL
d0 = 3.15; % Distancia de referencia en metros
PL_d0 = 20*log10(4*pi*d0*f/c); % FSPL en d0
fprintf('Anclaje del modelo: d0 = %.2f m, PL(d0) = %.2f dB (FSPL)\n', d0, PL_d0);

% Parámetro físico del quiebre
x1 = 39.4; % Distancia del punto de quiebre en metros

% --- Función de Costo (RMSE) para la Optimización ---
objective_function = @(params) ...
    rmse_quiebre_total(params(1), params(2), ...
                       d0, PL_d0, x1, ...
                       dist_total_los, pl_medido_los, ...
                       dist_total_nlos, pl_medido_nlos);

% Valores iniciales para la optimización
initial_guess = [2.0, 30]; 
options = optimset('Display', 'iter'); % Muestra el progreso
[optimal_params, min_rmse] = fminsearch(objective_function, initial_guess, options);

n_opt = optimal_params(1);
S_opt = optimal_params(2);

% --- 3. Reporte de Parámetros y RMSE ---
fprintf('\n--- Parámetros Optimizados (Global) ---\n');
fprintf('Exponente de Pérdida (n): %.2f\n', n_opt);
fprintf('Pérdida por Quiebre (S):  %.2f dB\n', S_opt);
fprintf('RMSE Global Mínimo:       %.2f dB\n', min_rmse);

% --- Calcular RMSE por separado para la tabla ---
% Generar predicciones con el modelo optimizado
pl_quiebre_los_opt = PL_d0 + 10 * n_opt * log10(dist_total_los/d0);

% Calcular predicciones NLOS (manejando índices válidos)
distancia_desde_quiebre = dist_total_nlos - x1;
valid_idx = distancia_desde_quiebre >= 0; % Usar >= 0 para incluir el primer punto
dist_nlos_validos = dist_total_nlos(valid_idx);
pl_nlos_validos = pl_medido_nlos(valid_idx);

% --- CÁLCULO DE PREDICCIÓN NLOS CORREGIDO ---
pl_quiebre_nlos_opt = (PL_d0 + 10*n_opt*log10(x1/d0)) + S_opt + 10*n_opt*log10( dist_nlos_validos / x1 );

% Calcular RMSE separados
rmse_los = sqrt(mean((pl_medido_los - pl_quiebre_los_opt).^2));
rmse_nlos = sqrt(mean((pl_nlos_validos - pl_quiebre_nlos_opt).^2));

fprintf('\n----------- TABLA FINAL RMSE [dB] -----------\n');
fprintf('Modelo Quiebre    |  LOS    |  NLOS  |  Ambos \n');
fprintf('------------------|---------|--------|---------\n');
fprintf('Optimizado (n, S) |  %5.3f  |  %5.3f |  %5.3f\n', rmse_los, rmse_nlos, min_rmse);
fprintf('---------------------------------------------\n');

% --- 4. Gráfico Final (Estilo CI) ---
fprintf('Generando gráfico en escala lineal...\n');
figure('Name', 'Modelo de Quiebre vs. Mediciones (Todas las Alturas)');
hold on;

% --- Opciones de visualización ---
poster_line_width = 3.5; 
poster_marker_size = 5; 
poster_font_size = 20; 
colors_medido = {[0.5 0.2 0.8], [0.8 0.5 0.2], [0.1 0.7 0.5]};

% --- Graficar Puntos de Medición (por altura) ---
for i = 1:length(alturas)
    datos = load(archivos{i});
    
    % Graficar datos LOS (círculo relleno)
    plot(datos.distancias_los, datos.pl_lee_los, 'o', ...
         'MarkerSize', poster_marker_size, ...
         'MarkerEdgeColor', colors_medido{i}, ...
         'MarkerFaceColor', colors_medido{i}, ...
         'DisplayName', sprintf('Datos LOS h_r=%.2f m', alturas(i)));
         
    % Graficar datos NLOS (círculo vacío)
    plot(datos.distancias_nlos, datos.pl_lee_nlos, 'o', ...
         'MarkerSize', poster_marker_size, ...
         'MarkerEdgeColor', colors_medido{i}, ...
         'MarkerFaceColor', 'none', ...
         'DisplayName', sprintf('Datos NLOS h_r=%.2fm', alturas(i)));
end

% --- Graficar Líneas del Modelo Optimizado ---

% Curva Modelo LOS
% (Se extiende desde d0 hasta x1)
dist_los_modelo = linspace(d0, x1, 200);
pl_modelo_global_los = PL_d0 + 10 * n_opt * log10(dist_los_modelo / d0);

plot(dist_los_modelo, pl_modelo_global_los, 'k-', ...
     'LineWidth', poster_line_width, ...
     'DisplayName', sprintf('Modelo LOS (n=%.2f)', n_opt));

% Curva Modelo NLOS
% (Se extiende desde x1 hasta el final)
dist_nlos_modelo = linspace(x1, max(dist_total_nlos), 200);

% --- CÁLCULO DE LÍNEA DE GRÁFICO NLOS CORREGIDO ---
pl_modelo_global_nlos = (PL_d0 + 10*n_opt*log10(x1/d0)) + S_opt + 10*n_opt*log10( dist_nlos_modelo / x1 );

plot(dist_nlos_modelo, pl_modelo_global_nlos, 'r-', ...
     'LineWidth', poster_line_width, ...
     'DisplayName', sprintf('Modelo NLOS (S=%.1f dB)', S_opt));

% Curva de Friis en Espacio Libre
dist_friis = linspace(min(dist_total_global), max(dist_total_global), 200);
pl_friis = 20 * log10(4 * pi * dist_friis / lambda);
plot(dist_friis, pl_friis, '--', 'Color', [0.3 0.3 0.3], ...
     'LineWidth', poster_line_width - 1, 'DisplayName', 'Espacio Libre');

% % --- LÍNEA DE QUIEBRE ELIMINADA ---
% color_quiebre = [0.3 0.3 0.3];
% xline(x1, ':', 'Color', color_quiebre, 'LineWidth', poster_line_width - 1, ...
%       'DisplayName', sprintf('Quiebre (x_1=%.1f m)', x1));

% --- Ajustes Finales del Gráfico ---
hold off;
grid on;
box on; 
ax = gca;
ax.GridAlpha = 0.4;
ax.Layer = 'top';

% Leyenda: Posición y tamaño optimizados
leg = legend('Location', 'northwest', 'NumColumns', 2);
leg.FontSize = poster_font_size * 0.8; 
title('Pérdida de Trayectoria vs. Distancia: Modelo de Quiebre vs. Mediciones', 'FontSize', poster_font_size * 1.2, 'FontWeight', 'bold');
xlabel('Distancia Manhattan [m]', 'FontSize', poster_font_size);
ylabel('Pérdida de Trayectoria [dB]', 'FontSize', poster_font_size);
xlim([min(dist_total_global), max(dist_total_global)]);
ylim([40 160]); % Ajusta según tus datos
set(gca, 'FontSize', poster_font_size); 

fprintf('Proceso finalizado. El gráfico ha sido optimizado para publicación.\n');

% --- Impresión del Modelo Explicito de Path Loss (DS) ---
PL_x1_explicit = PL_d0 + 10 * n_opt * log10(x1 / d0);
fprintf('\n--- Modelo Explicito de Path Loss Dual-Slope (PL[dB] = ...) ---\n');
fprintf('PL(d)[dB] = {\n');
fprintf('  %.2f + 10(%.2f) * log10(d/%.2f) + Xsigma\t\tsi d <= %.2f (LOS)\n', PL_d0, n_opt, d0, x1);
fprintf('  %.2f + %.2f + 10(%.2f) * log10(d/%.2f) + Xsigma\t\tsi d > %.2f (NLOS)\n', PL_x1_explicit, S_opt, n_opt, x1, x1);
fprintf('}\n');


% --- 5. Función Auxiliar para la Optimización ---
function rmse_val = rmse_quiebre_total(n, S, d0, PL_d0, x1, dist_los, pl_lee_los, dist_nlos, pl_lee_nlos)
    
    % --- Predicción LOS ---
    % Válido para todos los puntos dist_los (asumiendo que todos son <= x1)
    % Filtrar por si acaso hay puntos LOS más allá del quiebre
    los_valid_idx = dist_los <= x1;
    pl_pred_los = PL_d0 + 10 * n * log10(dist_los(los_valid_idx)/d0);
    
    % --- Predicción NLOS ---
    dist_desde_quiebre = dist_nlos - x1;
    % Incluir puntos que están en o después del quiebre
    valid_idx = dist_desde_quiebre >= 0;
    
    % Manejar caso donde no hay puntos NLOS válidos
    if ~any(valid_idx)
        % Calcular error solo con LOS
        rmse_val = sqrt(mean((pl_lee_los(los_valid_idx) - pl_pred_los).^2));
        return;
    end
    
    dist_nlos_validos = dist_nlos(valid_idx);
    pl_nlos_validos = pl_lee_nlos(valid_idx);
    
    % Evitar log(0) o log(negativo) si los parámetros son malos
    if x1 <= 0 || d0 <= 0 || any(dist_los(los_valid_idx) <= 0) || any(dist_nlos_validos <= 0)
        rmse_val = 1e9; % Penalización alta
        return;
    end

    % --- FÓRMULA CORREGIDA PARA PREDICCIÓN NLOS ---
    % PL_NLOS(d) = PL(x1) + S + 10*n*log10(d / x1)
    PL_en_x1 = PL_d0 + 10*n*log10(x1/d0);
    pl_pred_nlos = PL_en_x1 + S + 10*n*log10( dist_nlos_validos / x1 );
    
    % --- Combinar mediciones y predicciones para el error total ---
    pl_medido_total = [pl_lee_los(los_valid_idx); pl_nlos_validos];
    pl_pred_total = [pl_pred_los; pl_pred_nlos];
    
    % Calcular RMSE total
    rmse_val = sqrt(mean((pl_medido_total - pl_pred_total).^2));
end