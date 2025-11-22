% Script para Analizar y Promediar Datos de Potencia de Escenarios LOS y NLOS
% Se utiliza la interpolación a una grilla de distancia común antes de promediar
% para evitar el cruce de datos por diferentes velocidades de muestreo.
clc;
clear;
close all;
% --- CONFIGURACION Y PARAMETROS GLOBALES ---
carpeta_datos = './'; 
num_puntos_interpolacion = 1000; % Número de puntos para la grilla de distancia equiespaciada
% Parámetros para el escenario de LOS 
patron_archivos_los = 'R50*_dataMC.mat'; 
distancia_inicio_los_m = 39.4; 
distancia_fin_los_m = 3.15;     
distancia_recorrida_los_m = distancia_inicio_los_m - distancia_fin_los_m;
% Parámetros para el escenario NLOS
patron_archivos_nlos = 'R50*_dataMC_NLOS.mat'; 
coordenada_x_nlos_m = 39.4;       % X-fija para el recorrido NLOS
desplazamiento_y_inicio_nlos_m = 15.25;
desplazamiento_y_fin_nlos_m = 0;
distancia_recorrida_nlos_m = desplazamiento_y_inicio_nlos_m - desplazamiento_y_fin_nlos_m;
% --- BUSQUEDA Y CARGA DE ARCHIVOS ---
archivos_los = dir(fullfile(carpeta_datos, patron_archivos_los));
if isempty(archivos_los)
    warning('No se encontraron archivos LOS que coincidan con el patron "%s".', patron_archivos_los);
    return;
end
archivos_nlos = dir(fullfile(carpeta_datos, patron_archivos_nlos));
if isempty(archivos_nlos)
    warning('No se encontraron archivos NLOS que coincidan con el patron "%s".', patron_archivos_nlos);
    return;
end
disp('Archivos de datos encontrados. Iniciando procesamiento...');

% Inicializar celdas para almacenar todas las distancias y potencias para el gráfico combinado
all_distancias_los = cell(length(archivos_los), 1);
all_potencias_los = cell(length(archivos_los), 1);
all_distancias_nlos = cell(length(archivos_nlos), 1);
all_potencias_nlos = cell(length(archivos_nlos), 1);

% --- PROCESAMIENTO, INTERPOLACION Y GRAFICOS INDIVIDUALES LOS ---
disp('Procesando y graficando mediciones individuales de LOS...');
% Inicializar matriz para almacenar los datos interpolados
datos_los_interpolados = zeros(num_puntos_interpolacion, length(archivos_los));
figure('Name', 'Mediciones Individuales LOS', 'NumberTitle', 'off');
hold on;
title('Potencia Recibida vs Distancia: Mediciones Individuales LOS');
xlabel('Distancia desde Transmisor [m]');
ylabel('Potencia Recibida Efectiva [dBm]');
grid on;
% Grilla de distancia equiespaciada para la interpolación
distancia_grilla_los = linspace(distancia_inicio_los_m, distancia_fin_los_m, num_puntos_interpolacion)';
for i = 1:length(archivos_los)
    ruta_completa_archivo = fullfile(carpeta_datos, archivos_los(i).name);
    datos_cargados = load(ruta_completa_archivo);
    datos_mc = datos_cargados.dataMC;
    % Calcular la distancia recorrida para esta medición
    marcas_tiempo = seconds(datos_mc.Timestamp - datos_mc.Timestamp(1));
    tiempo_total_segundos = marcas_tiempo(end);
    
    if tiempo_total_segundos == 0
        warning('El archivo %s tiene una duración de tiempo de 0. Saltando...', archivos_los(i).name);
        continue;
    end
    
    velocidad_efectiva = distancia_recorrida_los_m / tiempo_total_segundos;
    distancias_muestreadas = distancia_inicio_los_m - (marcas_tiempo * velocidad_efectiva);
    
    % Interpolación
    potencia_interpolada = interp1(distancias_muestreadas, datos_mc.pRx, distancia_grilla_los, 'linear');
    
    % Almacenar los datos interpolados en la matriz
    datos_los_interpolados(:, i) = potencia_interpolada;
    
    % Almacenar para el gráfico combinado
    all_distancias_los{i} = distancias_muestreadas;
    all_potencias_los{i} = datos_mc.pRx;
    
    % Graficar la medición individual (SIN DisplayName y SIN legend)
    plot(distancias_muestreadas, datos_mc.pRx); 
end
hold off;

% --- PROCESAMIENTO, INTERPOLACION Y GRAFICOS INDIVIDUALES NLOS ---
disp('Procesando y graficando mediciones individuales de NLOS...');
% Inicializar matriz para almacenar los datos interpolados
datos_nlos_interpolados = zeros(num_puntos_interpolacion, length(archivos_nlos));
figure('Name', 'Mediciones Individuales NLOS', 'NumberTitle', 'off');
hold on;
title('Potencia Recibida vs Distancia: Mediciones Individuales NLOS');
xlabel('Distancia desde Transmisor [m]');
ylabel('Potencia Recibida Efectiva [dBm]');
grid on;
% Grilla de distancia equiespaciada para la interpolación
distancia_y_grilla_nlos = linspace(desplazamiento_y_inicio_nlos_m, desplazamiento_y_fin_nlos_m, num_puntos_interpolacion)';
distancia_grilla_nlos = coordenada_x_nlos_m + distancia_y_grilla_nlos;
for i = 1:length(archivos_nlos)
    ruta_completa_archivo = fullfile(carpeta_datos, archivos_nlos(i).name);
    datos_cargados = load(ruta_completa_archivo);
    datos_mc = datos_cargados.dataMC;
    % Calcular la distancia recorrida para esta medición
    marcas_tiempo = seconds(datos_mc.Timestamp - datos_mc.Timestamp(1));
    tiempo_total_segundos = marcas_tiempo(end);
    
    if tiempo_total_segundos == 0
        warning('El archivo %s tiene una duración de tiempo de 0. Saltando...', archivos_nlos(i).name);
        continue;
    end
    velocidad_efectiva_y = distancia_recorrida_nlos_m / tiempo_total_segundos;
    distancia_y_muestreada = desplazamiento_y_inicio_nlos_m - (marcas_tiempo * velocidad_efectiva_y);
    distancias_muestreadas = coordenada_x_nlos_m + distancia_y_muestreada;
    
    % Interpolación
    potencia_interpolada = interp1(distancias_muestreadas, datos_mc.pRx, distancia_grilla_nlos, 'linear');
    
    % Almacenar los datos interpolados en la matriz
    datos_nlos_interpolados(:, i) = potencia_interpolada;
    
    % Almacenar para el gráfico combinado
    all_distancias_nlos{i} = distancias_muestreadas;
    all_potencias_nlos{i} = datos_mc.pRx;
    
    % Graficar la medición individual (SIN DisplayName y SIN legend)
    plot(distancias_muestreadas, datos_mc.pRx); 
end
hold off;

% --- NUEVA FIGURA: COMBINADA DE TODAS LAS MEDICIONES INDIVIDUALES LOS + NLOS ---
disp('Generando gráfico combinado de todas las mediciones individuales...');
figure('Name', 'Mediciones Individuales Combinadas LOS y NLOS', 'NumberTitle', 'off');
hold on;
title('Potencia Recibida vs Distancia: Mediciones Individuales LOS y NLOS');
xlabel('Distancia desde Transmisor [m]');
ylabel('Potencia Recibida Efectiva [dBm]');
grid on;

% Definir mapa de colores para las mediciones LOS y NLOS (misma paleta 'lines')
max_archivos = max(length(archivos_los), length(archivos_nlos));
% Se usa 'hsv' o 'jet' para un mayor contraste, pero mantendremos 'lines' si es el objetivo.
% Usaremos 'lines' para una distribución cíclica de colores
colors = lines(max_archivos); 

% Graficar las mediciones individuales LOS (colores distintos, sin leyenda)
for i = 1:length(all_distancias_los)
    if ~isempty(all_distancias_los{i})
        % Asignar color de la paleta 'lines'
        plot(all_distancias_los{i}, all_potencias_los{i}, 'Color', colors(i,:), 'LineStyle', '-', 'LineWidth', 0.5); 
    end
end

% Graficar las mediciones individuales NLOS (mismos colores que LOS, pero línea punteada)
for i = 1:length(all_distancias_nlos)
    if ~isempty(all_distancias_nlos{i})
        % Asignar el mismo color de la paleta 'lines' para el NLoS i-ésimo
        % Se utiliza una línea punteada para diferenciar visualmente NLOS de LOS
        plot(all_distancias_nlos{i}, all_potencias_nlos{i}, 'Color', colors(i,:), 'LineStyle', ':', 'LineWidth', 1.0); 
    end
end
% No se incluye legend ni DisplayName
hold off;

% --- CALCULO Y GRAFICOS DE LOS PROMEDIOS ---
disp('Calculando promedios y generando gráficos finales...');
% Promedio de los datos interpolados (por columna)
promedio_los_dbm = mean(datos_los_interpolados, 2, 'omitnan');
promedio_nlos_dbm = mean(datos_nlos_interpolados, 2, 'omitnan');
% --- INICIO DEL FILTRADO DE DATOS PROMEDIOS ---
disp('Filtrando curvas promedio para eliminar ruido...');
umbral_potencia_los_dbm = -94;
umbral_potencia_nlos_dbm = -110;
% Aplicar umbral para filtrar los datos promediados
indices_validos_los = promedio_los_dbm >= umbral_potencia_los_dbm;
distancias_los_filtrado = distancia_grilla_los(indices_validos_los);
promedio_los_dbm_filtrado = promedio_los_dbm(indices_validos_los);
indices_validos_nlos = promedio_nlos_dbm >= umbral_potencia_nlos_dbm;
distancias_nlos_filtrado = distancia_grilla_nlos(indices_validos_nlos);
promedio_nlos_dbm_filtrado = promedio_nlos_dbm(indices_validos_nlos);
fprintf('Puntos LOS: %d originales, %d tras filtrar\n', length(promedio_los_dbm), length(promedio_los_dbm_filtrado));
fprintf('Puntos NLOS: %d originales, %d tras filtrar\n', length(promedio_nlos_dbm), length(promedio_nlos_dbm_filtrado));
% --- FIN DEL FILTRADO ---
% Guardar los datos promediados en un archivo .mat
save('datos_promediados_fase1.mat', 'distancias_los_filtrado', 'promedio_los_dbm_filtrado', 'distancias_nlos_filtrado', 'promedio_nlos_dbm_filtrado');
disp('Promedio final guardado en "datos_promediados_fase_1.mat".');
% Gráfico 1: Promedio LOS vs Promedio NLOS (Combinado)
figure('Name', 'Promedio LOS vs NLOS', 'NumberTitle', 'off');
plot(distancias_los_filtrado, promedio_los_dbm_filtrado, 'b-', 'LineWidth', 2, 'DisplayName', 'Promedio LOS'); 
hold on;
plot(distancias_nlos_filtrado, promedio_nlos_dbm_filtrado, 'r-', 'LineWidth', 2, 'DisplayName', 'Promedio NLOS'); 
hold off;
xlabel('Distancia desde Transmisor [m]');
ylabel('Potencia Recibida Efectiva [dBm]');
title('Curvas de Potencia Promedio: LOS vs NLOS');
grid on;
legend('Location', 'best');
% Gráfico 2: Promedio SOLO LOS
figure('Name', 'Promedio SOLO LOS', 'NumberTitle', 'off');
plot(distancias_los_filtrado, promedio_los_dbm_filtrado, 'b-', 'LineWidth', 2);
xlabel('Distancia desde Transmisor [m]');
ylabel('Potencia Recibida Efectiva [dBm]');
title('Curva de Potencia Promedio: SOLO LOS');
grid on;
% Gráfico 3: Promedio SOLO NLOS
figure('Name', 'Promedio SOLO NLOS', 'NumberTitle', 'off');
plot(distancias_nlos_filtrado, promedio_nlos_dbm_filtrado, 'r-', 'LineWidth', 2);
xlabel('Distancia desde Transmisor [m]');
ylabel('Potencia Recibida Efectiva [dBm]');
title('Curva de Potencia Promedio: SOLO NLOS');
grid on;
disp('Proceso completado. Se han generado todos los gráficos y se han guardado los datos promediados.');