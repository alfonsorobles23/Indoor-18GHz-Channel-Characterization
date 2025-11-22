% SCRIPT PARA CÁLCULO DE EPL Y GRÁFICO DE CDF
% Este script procesa datos LOS y NLOS de tres alturas diferentes
% para calcular la Pérdida de Trayectoria en Exceso (EPL) y graficar su
% Función de Distribución Acumulada (CDF).
clc;
clear;
close all;
% --- 1. Configuración del Sistema y Carga de Datos ---
fprintf('Cargando datos de medición para las alturas seleccionadas...\n');
f = 18e9; % Frecuencia de la señal en Hz (18 GHz)
c = 3e8;  % Velocidad de la luz en m/s
lambda = c / f; % Longitud de onda
% Definir alturas y nombres de archivos correspondientes
alturas = [0.61, 1.30, 1.91]; % Alturas de la antena receptora en m
archivos = {'resultados_metodo_lee061.mat', 'resultados_metodo_lee130.mat', 'resultados_metodo_lee191.mat'};
% --- 2. Almacenamiento de Datos EPL y CDF ---
% Inicializar cell arrays para almacenar datos de EPL para cada altura
epl_los_data = cell(1, length(alturas));
epl_nlos_data = cell(1, length(alturas));
dist_los_all = []; % Inicializar arreglo para todas las distancias LOS
dist_nlos_all = []; % Inicializar arreglo para todas las distancias NLOS
% --- 3. Procesar Datos para Cada Altura ---
for i = 1:length(alturas)
    try
        datos = load(archivos{i});
        fprintf('Procesando archivo "%s" para h_r = %.2f m...\n', archivos{i}, alturas(i));
        % Obtener distancias y PL medido para escenarios LOS y NLOS
        dist_los = datos.distancias_los;
        pl_los = datos.pl_lee_los;
        dist_nlos = datos.distancias_nlos;
        pl_nlos = datos.pl_lee_nlos;
        % Calcular Pérdida de Trayectoria en Espacio Libre (FSPL) para ambos escenarios
        pl_fs_los = 20 * log10(4 * pi * dist_los / lambda);
        pl_fs_nlos = 20 * log10(4 * pi * dist_nlos / lambda);
        % Calcular Pérdida de Trayectoria en Exceso (EPL) para ambos escenarios
        epl_los = pl_los - pl_fs_los;
        epl_nlos = pl_nlos - pl_fs_nlos;
        % Almacenar datos de EPL y distancia
        epl_los_data{i} = epl_los;
        epl_nlos_data{i} = epl_nlos;
        dist_los_all = [dist_los_all; dist_los];
        dist_nlos_all = [dist_nlos_all; dist_nlos];
    catch
        warning('No se pudo encontrar el archivo "%s". Saltando a la siguiente altura.', archivos{i});
    end
end
% --- 4. Gráfico 1: EPL vs. Distancia ---
fprintf('\nGenerando gráfico EPL vs. Distancia...\n');
figure('Name', 'Pérdida de Trayectoria en Exceso vs. Distancia');
hold on;
font_size = 20;
% Nueva paleta de colores para EPL vs. Distancia (tonos de azul y naranja)
colors = {[0 0.4470 0.7410], [0.8500 0.3250 0.0980], [0.4660 0.6740 0.1880], [0.6350 0.0780 0.1840], [0.4940 0.1840 0.5560], [0.3010 0.7450 0.9330]};
for i = 1:length(alturas)
    datos = load(archivos{i}); % Recargar datos para el bucle de graficado
    % Graficar datos LOS
    plot(datos.distancias_los, epl_los_data{i}, ...
         'Marker', '.', 'Color', colors{i}, 'MarkerSize', 20, ...
         'LineStyle', 'none', ...
         'DisplayName', sprintf('LOS (h_r = %.2f m)', alturas(i)));
    % Graficar datos NLOS
    plot(datos.distancias_nlos, epl_nlos_data{i}, ...
         'Marker', 'o', 'Color', colors{i}, 'MarkerSize', 6, ...
         'LineStyle', 'none', ...
         'DisplayName', sprintf('NLOS (h_r = %.2f m)', alturas(i)));
end
hold off;
grid on;
box on;
xlabel('Distancia Manhattan [m]','FontSize',25);
ylabel('EPL [dB]','FontSize',25);
title('EPL vs. Distancia','FontSize',25*1.2);
% Establecer los límites del eje X
all_distances = [dist_los_all; dist_nlos_all];
if ~isempty(all_distances)
    xlim([min(all_distances) max(all_distances)]);
end
leg = legend('show', 'Location', 'northeast');
leg.FontSize = 20;
set(gca,'FontSize',20)
set(findall(gcf, '-property', 'FontName'), 'FontName', 'Times New Roman');
%set(findall(gcf, '-property', 'FontSize'), 'FontSize', 10);
fprintf('Gráfico EPL vs. Distancia generado con éxito.\n');
% --- 5. Gráfico 2: CDF de EPL ---
fprintf('Generando gráfico CDF de EPL...\n');
figure('Name', 'CDF de EPL');
hold on;
% Colores originales para el CDF
colors_cdf = {'r', 'g', 'b'};
for i = 1:length(alturas)
    % Calcular y graficar CDF para LOS
    [f_los, x_los] = ecdf(epl_los_data{i});
    plot(x_los, f_los, 'Color', colors_cdf{i}, ...
         'LineWidth', 4, 'DisplayName', sprintf('LOS (h_r = %.2f m)', alturas(i)));
    % Calcular y graficar CDF para NLOS
    [f_nlos, x_nlos] = ecdf(epl_nlos_data{i});
    plot(x_nlos, f_nlos, '--', 'Color', colors_cdf{i}, 'LineWidth', 4, ...
         'DisplayName', sprintf('NLOS (h_r = %.2f m)', alturas(i)));
end
hold off;
grid on;
box on;
xlabel('EPL [dB]','FontSize',25);
ylabel('CDF','FontSize',25);
title('CDF de Pérdida de Trayectoria en Exceso','FontSize',25*1.2);
leg = legend('show', 'Location', 'southeast');
leg.FontSize = 15;
set(gca,'FontSize',20)
set(findall(gcf, '-property', 'FontName'), 'FontName', 'Times New Roman');
%set(findall(gcf, '-property', 'FontSize'), 'FontSize', 10);
fprintf('Gráfico CDF de EPL generado con éxito.\n');
% --- 6. Mostrar Métricas Estadísticas ---
fprintf('\n--- Métricas Estadísticas para Pérdida de Trayectoria en Exceso (EPL) ---\n');
for i = 1:length(alturas)
    % Calcular métricas para LOS
    mediana_los = median(epl_los_data{i});
    p90_los = prctile(epl_los_data{i}, 90);
    promedio_los = mean(epl_los_data{i});
    desv_std_los = std(epl_los_data{i});
    
    % Calcular métricas para NLOS
    mediana_nlos = median(epl_nlos_data{i});
    p90_nlos = prctile(epl_nlos_data{i}, 90);
    promedio_nlos = mean(epl_nlos_data{i});
    desv_std_nlos = std(epl_nlos_data{i});
    
    % Mostrar resultados
    fprintf('\nMétricas para h_r = %.2f m:\n', alturas(i));
    fprintf('  - LOS: Mediana = %.2f dB | P90 = %.2f dB | Promedio = %.2f dB | Desv. Est. = %.2f dB\n', mediana_los, p90_los, promedio_los, desv_std_los);
    fprintf('  - NLOS: Mediana = %.2f dB | P90 = %.2f dB | Promedio = %.2f dB | Desv. Est. = %.2f dB\n', mediana_nlos, p90_nlos, promedio_nlos, desv_std_nlos);
end
fprintf('\nTodos los procesos completados.\n');