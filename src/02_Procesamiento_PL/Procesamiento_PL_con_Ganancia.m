% SCRIPT PARA APLICAR EL MÉTODO DE LEE (VERSIÓN CON GANANCIA VARIABLE)
% Este script carga los datos filtrados, calcula el path loss (con ganancia
% variable para LOS), aplica el método de Lee, genera los gráficos y 
% guarda los resultados finales en un archivo .mat.
clc;
clear;
close all;

% --- 1. Configuración del Sistema y Carga de Datos ---
fprintf('Cargando datos promediados y filtrados...\n');
try
    % Carga los datos de potencia y distancia para la altura de 0.61m
    datos_cargados = load('datos_promediados_fase1_061.mat');
    fprintf('Archivo "datos_promediados_fase1_061.mat" cargado con éxito.\n');
catch
    error('No se pudo encontrar el archivo "datos_promediados_fase1_061.mat". Asegúrese de que esté en el mismo directorio que el script.');
end

%%% NUEVO: Cargar el patrón de antena calibrado %%%
fprintf('Cargando patrón de antena calibrado...\n');
try
    datos_patron = load('Patron_Calibrado_18_000_GHz.mat');
    % Extraer los vectores de la tabla para usar con interp1
    patron_grados = datos_patron.patronTabla_dBi.grados;
    patron_ganancia_dBi = datos_patron.patronTabla_dBi.ganancia_dBi;
    fprintf('Patrón de antena "Patron_Calibrado_18_000_GHz.mat" cargado con éxito.\n');
catch ME
    error('No se pudo cargar el archivo del patrón de antena "Patron_Calibrado_18_000_GHz.mat". Error: %s', ME.message);
end

% --- 1.2 Parámetros del experimento ---
f = 18e9;                       % Frecuencia de la señal en Hz (18 GHz)
c = 3e8;                        % Velocidad de la luz en m/s
LCables_dB = 3.3994;            % Pérdidas de los cables en dB [cite: 840] (valor similar)

%%% NUEVO: Parámetros geométricos y de ganancia %%%
G_boresight_dBi = 21.1;         % Ganancia máxima (boresight) de las antenas en dBi [cite: 840]
H_tx_m = 1.3;                   % Altura fija del transmisor (Tx) en metros [cite: 840]
H_rx_m = 0.61;                  % Altura del receptor (Rx) para ESTE CASO [cite: 840]
delta_H_m = H_tx_m - H_rx_m;    % Diferencia de altura

% Parámetros específicos del escenario LOS
pTx_dBm_los = 0;                
 
% Parámetros específicos del escenario NLOS
pTx_dBm_nlos = 10;            
 

% --- 2. Cálculo del Path Loss (PL) Bruto ---
fprintf('Calculando el Path Loss bruto a partir de los datos filtrados...\n');

% --- 2.1 Cálculo para NLOS (Ganancia Fija) ---
% Para NLOS, se asume la ganancia máxima (boresight) ya que el ángulo es desconocido.
link_budget_constant_nlos = pTx_dBm_nlos + G_boresight_dBi + G_boresight_dBi - LCables_dB;
pl_raw_nlos_db = link_budget_constant_nlos - datos_cargados.promedio_nlos_dbm_filtrado;
fprintf('    PL Bruto NLOS calculado con ganancia fija (%.2f dBi).\n', G_boresight_dBi);

% --- 2.2 Cálculo para LOS (Ganancia Variable) ---
fprintf('    Calculando ganancia variable para LOS (h_rx = %.2f m)...\n', H_rx_m);

% Obtener el vector de distancias LOS
distancias_los_m = datos_cargados.distancias_los_filtrado;

% Calcular el vector de ángulos de desviación (en grados)
% Se usa 'atand' para obtener el resultado directamente en grados
angulos_desviacion_grados = atand(delta_H_m ./ distancias_los_m);

% Interpolar la ganancia para cada ángulo usando el patrón cargado
% Se asume que el patrón es el mismo para TX y RX (G_variable_dBi)
G_variable_dBi = interp1(patron_grados, patron_ganancia_dBi, angulos_desviacion_grados, 'spline', 'extrap');

% Advertencia si se está extrapolando (ángulos fuera del patrón medido)
if any(angulos_desviacion_grados < min(patron_grados)) || any(angulos_desviacion_grados > max(patron_grados))
    warning('Extrapolación de ganancia: Algunos ángulos (%.2f a %.2f) están fuera del rango de caracterización (%.2f a %.2f).', ...
            min(angulos_desviacion_grados), max(angulos_desviacion_grados), min(patron_grados), max(patron_grados));
end

% Calcular el Path Loss Bruto para LOS (punto a punto)
% PL = Ptx + Gtx_var + Grx_var - Lcables - Aten - Prx
% Gtx_variable y Grx_variable son el mismo vector G_variable_dBi
pl_raw_los_db = pTx_dBm_los + G_variable_dBi + G_variable_dBi - LCables_dB  - datos_cargados.promedio_los_dbm_filtrado;

fprintf('    PL Bruto LOS calculado con ganancia variable (G_tx y G_rx).\n');


% --- 3. Aplicación del Método de Lee (Promediado de Ventana Móvil) ---
% (Esta sección no necesita cambios, ya que toma los vectores 'pl_raw' calculados)
fprintf('Aplicando el método de Lee para el promediado...\n');
lambda = c / f;
window_size_in_lambda = 40;
spatial_window_m = window_size_in_lambda * lambda;
fprintf('    Longitud de onda (λ): %.4f m\n', lambda);
fprintf('    Ventana espacial (2L = %dλ): %.4f m\n', window_size_in_lambda, spatial_window_m);

% -- Procesamiento para LOS --
avg_sample_spacing_los_m = mean(abs(diff(datos_cargados.distancias_los_filtrado)));
window_size_points_los = round(spatial_window_m / avg_sample_spacing_los_m);
if mod(window_size_points_los, 2) == 0, window_size_points_los = window_size_points_los + 1; end
if isnan(window_size_points_los), window_size_points_los = 1; end 
fprintf('    Ventana LOS: %d puntos\n', window_size_points_los);
pl_raw_los_linear = 10.^(pl_raw_los_db / 10);
pl_avg_los_linear = movmean(pl_raw_los_linear, window_size_points_los, 'omitnan');
pl_avg_los_db = 10 * log10(pl_avg_los_linear);

% -- Procesamiento para NLOS --
avg_sample_spacing_nlos_m = mean(abs(diff(datos_cargados.distancias_nlos_filtrado)));
window_size_points_nlos = round(spatial_window_m / avg_sample_spacing_nlos_m);
if mod(window_size_points_nlos, 2) == 0, window_size_points_nlos = window_size_points_nlos + 1; end
if isnan(window_size_points_nlos), window_size_points_nlos = 1; end 
fprintf('    Ventana NLOS: %d puntos\n', window_size_points_nlos);
pl_raw_nlos_linear = 10.^(pl_raw_nlos_db / 10);
pl_avg_nlos_linear = movmean(pl_raw_nlos_linear, window_size_points_nlos, 'omitnan');
pl_avg_nlos_db = 10 * log10(pl_avg_nlos_linear);
fprintf('Promediado completado.\n');

% --- 4. Generación de Gráficos Comparativos ---
% (Sección modificada para incluir la altura en los títulos)
fprintf('Generando gráficos comparativos...\n');

% Gráfico 1: SOLO LOS (Bruto vs. Promediado)
figure('Name', 'Path Loss: LOS');
plot(datos_cargados.distancias_los_filtrado, pl_raw_los_db, '.', 'Color', [0.6 0.6 1], 'DisplayName', 'PL Bruto LOS (G. Var.)');
hold on;
plot(datos_cargados.distancias_los_filtrado, pl_avg_los_db, 'b.', 'MarkerSize', 8, 'DisplayName', 'PL Promediado (Lee) LOS');
hold off;
grid on; xlabel('Distancia [m]'); ylabel('Path Loss [dB]');
title(sprintf('Path Loss en Escenario LOS (h_{rx} = %.2f m): Bruto vs. Promediado', H_rx_m)); %%% MODIFICADO %%%
legend('Location', 'best');
set(findall(gcf,'-property','FontName'),'FontName','Times New Roman','FontSize',20);

% Gráfico 2: SOLO NLOS (Bruto vs. Promediado)
figure('Name', 'Path Loss: NLOS');
plot(datos_cargados.distancias_nlos_filtrado, pl_raw_nlos_db, '.', 'Color', [1 0.6 0.6], 'DisplayName', 'PL Bruto NLOS (G. Fija)');
hold on;
plot(datos_cargados.distancias_nlos_filtrado, pl_avg_nlos_db, 'r.', 'MarkerSize', 8, 'DisplayName', 'PL Promediado (Lee) NLOS');
hold off;
grid on; xlabel('Distancia [m]'); ylabel('Path Loss [dB]');
title(sprintf('Path Loss en Escenario NLOS (h_{rx} = %.2f m): Bruto vs. Promediado', H_rx_m)); %%% MODIFICADO %%%
legend('Location', 'best');
set(findall(gcf,'-property','FontName'),'FontName','Times New Roman','FontSize',20);

% --- 5. Gráficos Adicionales (Solo Método de Lee) ---
fprintf('Generando gráficos adicionales solo con el método de Lee...\n');
% Gráfico 3: SOLO promediado de Lee para LOS
figure('Name', 'Path Loss: Solo Promedio Lee LOS');
plot(datos_cargados.distancias_los_filtrado, pl_avg_los_db, 'b.', 'MarkerSize', 8);
grid on; xlabel('Distancia [m]'); ylabel('Path Loss [dB]');
title(sprintf('Path Loss Promediado con Método de Lee (SOLO LOS, h_{rx} = %.2f m)', H_rx_m)); %%% MODIFICADO %%%
box on;
set(findall(gcf,'-property','FontName'),'FontName','Times New Roman','FontSize',20);

% Gráfico 4: SOLO promediado de Lee para NLOS
figure('Name', 'Path Loss: Solo Promedio Lee NLOS');
plot(datos_cargados.distancias_nlos_filtrado, pl_avg_nlos_db, 'r.', 'MarkerSize', 8);
grid on; xlabel('Distancia [m]'); ylabel('Path Loss [dB]');
title(sprintf('Path Loss Promediado con Método de Lee (SOLO NLOS, h_{rx} = %.2f m)', H_rx_m)); %%% MODIFICADO %%%
box on;
set(findall(gcf,'-property','FontName'),'FontName','Times New Roman','FontSize',20);

% Gráfico 5: Comparación de SOLO promediados de Lee
figure('Name', 'Path Loss: Comparación de Promedios Lee');
plot(datos_cargados.distancias_los_filtrado, pl_avg_los_db, 'b.', 'MarkerSize', 8, 'DisplayName', 'Promedio Lee LOS');
hold on;
plot(datos_cargados.distancias_nlos_filtrado, pl_avg_nlos_db, 'r.', 'MarkerSize', 8, 'DisplayName', 'Promedio Lee NLOS');
hold off;
grid on; xlabel('Distancia [m]'); ylabel('Path Loss [dB]');
title(sprintf('Comparación de Path Loss Promediado (h_{rx} = %.2f m)', H_rx_m)); %%% MODIFICADO %%%
legend('Location', 'best');
box on;
set(findall(gcf,'-property','FontName'),'FontName','Times New Roman','FontSize',20);

% --- 6. GRÁFICO NUEVO: Comparación Global de Promedios ---
fprintf('Generando gráfico de comparación global...\n');
figure('Name', 'Comparación Global de Promedios');
plot(datos_cargados.distancias_los_filtrado, pl_raw_los_db, '.', 'Color', [0.7 0.7 1], 'DisplayName', 'PL Bruto LOS (G. Var.)');
hold on;
plot(datos_cargados.distancias_los_filtrado, pl_avg_los_db, 'b-o', 'LineWidth', 1.5, 'MarkerSize', 2, 'DisplayName', 'PL Promediado (Lee) LOS');
plot(datos_cargados.distancias_nlos_filtrado, pl_raw_nlos_db, '.', 'Color', [1 0.7 0.7], 'DisplayName', 'PL Bruto NLOS (G. Fija)');
plot(datos_cargados.distancias_nlos_filtrado, pl_avg_nlos_db, 'r-s', 'LineWidth', 1.5, 'MarkerSize', 2, 'DisplayName', 'PL Promediado (Lee) NLOS');
hold off;
grid on; xlabel('Distancia [m]'); ylabel('Path Loss [dB]');
title(sprintf('Comparación Global: PL Bruto vs. PL Promediado (h_{rx} = %.2f m)', H_rx_m)); %%% MODIFICADO %%%
legend('Location', 'best');
box on;
set(findall(gcf,'-property','FontName'),'FontName','Times New Roman','FontSize',20);

% --- 7. Guardar Resultados en Archivo .mat ---
fprintf('Guardando resultados en archivo .mat...\n');

% Asignar resultados a variables con nombres claros (como tu original)
distancias_los = datos_cargados.distancias_los_filtrado;
pl_raw_los = pl_raw_los_db;      % Este es el PL bruto con ganancia variable
pl_lee_los = pl_avg_los_db;
distancias_nlos = datos_cargados.distancias_nlos_filtrado;
pl_raw_nlos = pl_raw_nlos_db;  % Este es el PL bruto con ganancia fija
pl_lee_nlos = pl_avg_nlos_db;

% Guardar las variables en un nuevo archivo .mat, con nombre específico
output_filename = sprintf('resultados_metodo_lee_h%.2fm.mat', H_rx_m); %%% MODIFICADO %%%
save(output_filename, ...
    'distancias_los', 'pl_raw_los', 'pl_lee_los', ...
    'distancias_nlos', 'pl_raw_nlos', 'pl_lee_nlos');
fprintf('Resultados guardados en "%s".\n', output_filename);

fprintf('Proceso finalizado.\n');