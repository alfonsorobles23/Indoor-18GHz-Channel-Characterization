% SCRIPT PARA OPTIMIZAR EL MODELO CI USANDO EL MÉTODO DEL ARTÍCULO
clc;
clear;
close all;
% --- 1. Configuración del Sistema y Carga de Datos ---
fprintf('Cargando datos de medición para las alturas seleccionadas...\n');
f = 18e9; % Frecuencia de la señal en Hz (18 GHz)
c = 3e8;  % Velocidad de la luz en m/s
lambda = c / f; % Longitud de onda
% Alturas de la antena receptora y archivos correspondientes
alturas = [0.61, 1.30, 1.91]; % Alturas de la antena receptora en m
archivos = {'resultados_metodo_lee061.mat', ...
            'resultados_metodo_lee130.mat', ...
            'resultados_metodo_lee191.mat'};
% Pre-asignación de memoria
temp_data = load(archivos{1});
n_los_points = length(temp_data.distancias_los);
n_nlos_points = length(temp_data.distancias_nlos);
total_files = length(archivos);
dist_total_los = zeros(n_los_points * total_files, 1);
pl_medido_los = zeros(n_los_points * total_files, 1);
dist_total_nlos = zeros(n_nlos_points * total_files, 1);
pl_medido_nlos = zeros(n_nlos_points * total_files, 1);
los_idx = 1;
nlos_idx = 1;
for i = 1:total_files
    try
        datos = load(archivos{i});
        fprintf('Archivo "%s" cargado para h_r = %.2f m.\n', archivos{i}, alturas(i));
        los_end_idx = los_idx + length(datos.distancias_los) - 1;
        nlos_end_idx = nlos_idx + length(datos.distancias_nlos) - 1;
        dist_total_los(los_idx:los_end_idx) = datos.distancias_los;
        pl_medido_los(los_idx:los_end_idx) = datos.pl_lee_los;
        dist_total_nlos(nlos_idx:nlos_end_idx) = datos.distancias_nlos;
        pl_medido_nlos(nlos_idx:nlos_end_idx) = datos.pl_lee_nlos;
        los_idx = los_end_idx + 1;
        nlos_idx = nlos_end_idx + 1;
    catch
        warning('Archivo "%s" no encontrado. Saltando a la siguiente altura.', archivos{i});
    end
end
dist_total_los = dist_total_los(1:los_idx-1);
pl_medido_los = pl_medido_los(1:los_idx-1);
dist_total_nlos = dist_total_nlos(1:nlos_idx-1);
pl_medido_nlos = pl_medido_nlos(1:nlos_idx-1);
dist_total_global = [dist_total_los; dist_total_nlos];
% --- 2. Ajuste del Modelo CI Según el Artículo ---
fprintf('\nIniciando ajuste del modelo CI con referencia en d0 = 3.15 m...\n');
d0 = 3.15; % Distancia de referencia en metros
% FSPL (Pérdidas en Espacio Libre) a la distancia de referencia
fspl_d0 = 20*log10(4*pi*d0*f/c);
% --- 2.1 Ajuste LOS ---
A_los = pl_medido_los - fspl_d0;
D_los = 10*log10(dist_total_los / d0);
n_los_opt = sum(D_los .* A_los) / sum(D_los.^2);
% Modelo CI determinista (sin Xsigma)
pl_modelo_los = fspl_d0 + 10*n_los_opt*log10(dist_total_los / d0);
% Desvanecimiento por sombra (residuos) y desviación estándar
Xsigma_los = pl_medido_los - pl_modelo_los;
sigma_los = sqrt(mean(Xsigma_los.^2));
% --- 2.2 Ajuste NLOS ---
A_nlos = pl_medido_nlos - fspl_d0;
D_nlos = 10*log10(dist_total_nlos / d0);
n_nlos_opt = sum(D_nlos .* A_nlos) / sum(D_nlos.^2);
% Modelo CI determinista (sin Xsigma)
pl_modelo_nlos = fspl_d0 + 10*n_nlos_opt*log10(dist_total_nlos / d0);
% Desvanecimiento por sombra (residuos) y desviación estándar
Xsigma_nlos = pl_medido_nlos - pl_modelo_nlos;
sigma_nlos = sqrt(mean(Xsigma_nlos.^2));
% --- Reporte de Parámetros ---
fprintf('\n--- Parámetros CI Optimizados ---\n');
fprintf('Exponente de Pérdida de Trayectoria LOS (n_los): %.2f\n', n_los_opt);
fprintf('Exponente de Pérdida de Trayectoria NLOS (n_nlos): %.2f\n', n_nlos_opt);
fprintf('FSPL(f, d0=%.2f m): %.2f dB\n', d0, fspl_d0);
fprintf('\n--- Parámetros de Desvanecimiento por Sombra ---\n');
fprintf('Desv. Estándar Desvanecimiento LOS (sigma_los): %.2f dB\n', sigma_los);
fprintf('Desv. Estándar Desvanecimiento NLOS (sigma_nlos): %.2f dB\n', sigma_nlos);
fprintf('\n--- Mostrando algunos valores de Xsigma ---\n');
disp('Primeros 5 residuos LOS (Xsigma_los):');
disp(Xsigma_los(1:min(5,end)));
disp('Primeros 5 residuos NLOS (Xsigma_nlos):');
disp(Xsigma_nlos(1:min(5,end)));
fprintf('\n--- Modelos Finales de Pérdida de Trayectoria (CI Determinista + Residuos separados) ---\n');
fprintf('CI LOS:  PL = %.2f + 10 * %.2f * log10(d/%.2f) + Xsigma\n', fspl_d0, n_los_opt, d0);
fprintf('CI NLOS: PL = %.2f + 10 * %.2f * log10(d/%.2f) + Xsigma\n', fspl_d0, n_nlos_opt, d0);
% --- 3. Cálculo del RMSE (modelo determinista vs mediciones) ---
rmse_los = sqrt(mean((pl_medido_los - pl_modelo_los).^2));
rmse_nlos = sqrt(mean((pl_medido_nlos - pl_modelo_nlos).^2));
pl_pred_total = [pl_modelo_los; pl_modelo_nlos];
pl_medido_total = [pl_medido_los; pl_medido_nlos];
rmse_global_final = sqrt(mean((pl_medido_total - pl_pred_total).^2));
fprintf('\n----------- TABLA FINAL RMSE [dB] -----------\n');
fprintf('CI Determinista   |  LOS    |  NLOS  |  Ambos \n');
fprintf('------------------|---------|--------|---------\n');
fprintf('CI Optimizado     |  %5.3f  |  %5.3f |  %5.3f\n', rmse_los, rmse_nlos, rmse_global_final);
fprintf('---------------------------------------------\n');
% --- 4. Gráfico Final (Inglés, Times New Roman) ---
fprintf('Generando gráfico en escala lineal...\n');
figure('Name', 'Modelo CI vs. Mediciones (Escala Lineal)');
hold on;
% --- OPTIMIZACIONES PARA PUBLICACIÓN (VALORES MODIFICADOS) ---
poster_line_width = 3.5; % Grosor de línea aumentado para mayor visibilidad
poster_marker_size = 5; % Tamaño del marcador aumentado para mayor visibilidad
poster_font_size = 20; % Tamaño de fuente base para el gráfico
colors_medido = {[0.5 0.2 0.8], [0.8 0.5 0.2], [0.1 0.7 0.5]};
for i = 1:length(alturas)
    datos = load(archivos{i});
    dist_temp_los = datos.distancias_los;
    pl_temp_los = datos.pl_lee_los;
    
    % Graficar datos LOS con un marcador de círculo relleno
    plot(dist_temp_los, pl_temp_los, 'o', ...
         'MarkerSize', poster_marker_size, ...
         'MarkerEdgeColor', colors_medido{i}, ...
         'MarkerFaceColor', colors_medido{i}, ...
         'DisplayName', sprintf('Datos LOS h_r=%.2f m', alturas(i)));
    dist_temp_nlos = datos.distancias_nlos;
    pl_temp_nlos = datos.pl_lee_nlos;
    % Graficar datos NLOS con un marcador de círculo transparente
    plot(dist_temp_nlos, pl_temp_nlos, 'o', ...
         'MarkerSize', poster_marker_size, ...
         'MarkerEdgeColor', colors_medido{i}, ...
         'MarkerFaceColor', 'none', ...
         'DisplayName', sprintf('Datos NLOS h_r=%.2fm', alturas(i)));
end
% Curva CI LOS (determinista)
los_range = [min(dist_total_los), max(dist_total_los)];
manhattan_dist_los_model = linspace(los_range(1), los_range(2), 200);
pl_modelo_global_los = fspl_d0 + 10*n_los_opt*log10(manhattan_dist_los_model / d0);
plot(manhattan_dist_los_model, pl_modelo_global_los, 'k-', ...
     'LineWidth', poster_line_width, 'DisplayName', 'Modelo CI: LOS');
% Curva CI NLOS (determinista)
nlos_range = [min(dist_total_nlos), max(dist_total_nlos)];
manhattan_dist_nlos_model = linspace(nlos_range(1), nlos_range(2), 200);
pl_modelo_global_nlos = fspl_d0 + 10*n_nlos_opt*log10(manhattan_dist_nlos_model / d0);
plot(manhattan_dist_nlos_model, pl_modelo_global_nlos, 'r-', ...
     'LineWidth', poster_line_width, 'DisplayName', 'Modelo CI: NLOS');
% Curva de Friis en Espacio Libre
dist_friis = linspace(min(dist_total_global), max(dist_total_global), 200);
pl_friis = 20 * log10(4 * pi * dist_friis / lambda);
plot(dist_friis, pl_friis, '--', 'Color', [0.3 0.3 0.3], ...
     'LineWidth', poster_line_width - 1, 'DisplayName', 'Espacio Libre');
hold off;
grid on;
box on; % Mantiene el recuadro, pero el resto de elementos serán más legibles
ax = gca;
ax.GridAlpha = 0.4;
ax.Layer = 'top';
% Leyenda: Posición y tamaño optimizados
leg = legend('Location', 'northwest', 'NumColumns', 2);
leg.FontSize = poster_font_size * 0.8; % Tamaño de la fuente para la leyenda (80% del tamaño base)
title('Pérdida de Trayectoria vs. Distancia: Modelo CI vs. Mediciones', 'FontSize', poster_font_size * 1.2, 'FontWeight', 'bold');
xlabel('Distancia Manhattan [m]', 'FontSize', poster_font_size);
ylabel('Pérdida de Trayectoria [dB]', 'FontSize', poster_font_size);
xlim([min(dist_total_global), max(dist_total_global)]);
ylim([40 160]);
set(gca, 'FontSize', poster_font_size); % Aumenta el tamaño de la fuente de los números en los ejes
fprintf('Proceso finalizado. El gráfico ha sido optimizado para publicación.\n');