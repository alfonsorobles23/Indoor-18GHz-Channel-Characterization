% SCRIPT PARA COMPARAR PÉRDIDA DE TRAYECTORIA NLOS PARA DIFERENTES DISTANCIAS AL QUIEBRE
clc;
clear;
close all;
% --- 1. Cargar Datos Procesados de Cada Escenario NLOS ---
fprintf('Cargando datos NLOS procesados para comparación...\n');
try
    % Caso NLOS 2: 39.4m TX al Quiebre
    load('resultados_metodo_lee_39.4.mat', 'distancias_nlos', 'pl_lee_nlos');
    dist_nlos_case2 = distancias_nlos;
    pl_nlos_case2 = pl_lee_nlos;
    
    % Caso NLOS 3: 19.7m TX al Quiebre
    load('resultados_metodo_lee_19.7.mat', 'distancias_nlos', 'pl_lee_nlos');
    dist_nlos_case3 = distancias_nlos;
    pl_nlos_case3 = pl_lee_nlos;
    
    % Caso NLOS 4: 9.9m TX al Quiebre
    load('resultados_metodo_lee_9.9.mat', 'distancias_nlos', 'pl_lee_nlos');
    dist_nlos_case4 = distancias_nlos;
    pl_nlos_case4 = pl_lee_nlos;
    
    fprintf('Todos los archivos de datos NLOS cargados con éxito.\n');
    
catch ME
    warning('Error al cargar uno o más archivos de datos. Por favor, asegúrese de que existan en el directorio actual.');
    fprintf('Detalles del error: %s\n', ME.message);
    return;
end
% --- 2. Generar Gráfico Comparativo ---
fprintf('\nGenerando gráfico comparativo de Pérdida de Trayectoria...\n');
figure('Name', 'Comparación de Pérdida de Trayectoria NLOS', 'NumberTitle', 'off');
hold on;
font_size = 25;
line_width = 2.5;
% Graficar cada caso NLOS
plot(dist_nlos_case2, pl_nlos_case2, 'r--', 'LineWidth', line_width, 'DisplayName', 'NLOS a 39.4m del quiebre');
plot(dist_nlos_case3, pl_nlos_case3, 'k:', 'LineWidth', line_width, 'DisplayName', 'NLOS a 19.7m del quiebre');
plot(dist_nlos_case4, pl_nlos_case4, 'b-.', 'LineWidth', line_width, 'DisplayName', 'NLOS a 9.9m del quiebre');
hold off;
grid on;
box on;
% Aplicar formato
xlabel('Distancia Manhattan [m]','FontSize',font_size);
ylabel('PL [dB]','FontSize',font_size);
title('Comparación PL: Diferentes Distancias TX al Quiebre','FontSize',1.2*font_size);
legend('show', 'Location', 'best');
set(findall(gcf, '-property', 'FontName'), 'FontName', 'Times New Roman');
set(gca,'FontSize',20)
%set(findall(gcf, '-property', 'FontSize'), 'FontSize', font_size);
fprintf('Gráfico comparativo generado con éxito.\n');
% --- 3. Mostrar Métricas Estadísticas ---
fprintf('\n--- Resumen de Métricas de Pérdida de Trayecto (Path Loss) ---\n');
% Caso 1: TX a 39.4m del quiebre
promedio_39_4 = mean(pl_nlos_case2);
mediana_39_4 = median(pl_nlos_case2);
std_dev_39_4 = std(pl_nlos_case2);
fprintf('NLOS a 39.4m del quiebre:\n');
fprintf('  - Promedio: %.2f dB\n', promedio_39_4);
fprintf('  - Mediana: %.2f dB\n', mediana_39_4);
fprintf('  - Desviación Estándar: %.2f dB\n', std_dev_39_4);
% Caso 2: TX a 19.7m del quiebre
promedio_19_7 = mean(pl_nlos_case3);
mediana_19_7 = median(pl_nlos_case3);
std_dev_19_7 = std(pl_nlos_case3);
fprintf('\nNLOS a 19.7m del quiebre:\n');
fprintf('  - Promedio: %.2f dB\n', promedio_19_7);
fprintf('  - Mediana: %.2f dB\n', mediana_19_7);
fprintf('  - Desviación Estándar: %.2f dB\n', std_dev_19_7);
% Caso 3: TX a 9.9m del quiebre
promedio_9_9 = mean(pl_nlos_case4);
mediana_9_9 = median(pl_nlos_case4);
std_dev_9_9 = std(pl_nlos_case4);
fprintf('\nNLOS a 9.9m del quiebre:\n');
fprintf('  - Promedio: %.2f dB\n', promedio_9_9);
fprintf('  - Mediana: %.2f dB\n', mediana_9_9);
fprintf('  - Desviación Estándar: %.2f dB\n', std_dev_9_9);
fprintf('\nProceso completado.\n');