# Caracterización del Canal Inalámbrico a 18 GHz en Corredores con Quiebre

**Autor:** Alfonso Andrés Robles Tapia  
**Institución:** Universidad Técnica Federico Santa María (UTFSM) - Departamento de Electrónica  
**Fecha:** Diciembre 2025

## 📄 Descripción del Proyecto

Este repositorio contiene el código fuente, datos y scripts de procesamiento desarrollados para la Memoria de Titulación: **"Caracterización del Canal Inalámbrico a 18 GHz en Corredores con Quiebre"**.

El proyecto investiga la propagación de ondas milimétricas en la banda de **18 GHz (FR3)** dentro de entornos interiores complejos (Indoor), específicamente en corredores de hormigón con intersecciones en L (L-Junction). El estudio se centra en modelar la transición de Línea de Vista (**LoS**) a Sin Línea de Vista (**NLoS**), cuantificando la pérdida por difracción y evaluando la viabilidad de esta frecuencia para futuras redes 5G y 6G.

### 🎯 Objetivos Principales
1. **Caracterizar** empíricamente el canal a 18 GHz mediante campañas de medición extensivas.
2. **Modelar** las pérdidas de propagación utilizando modelos *Close-In* (CI) y *Dual-Slope* (DS).
3. **Evaluar** el impacto de la altura del receptor y la geometría del quiebre en la estabilidad del enlace.
4. **Comparar** los resultados experimentales con los estándares internacionales (3GPP TR 38.901 e ITU-R P.1238).

---

## 📊 Resultados Clave

Los análisis realizados con los scripts de este repositorio arrojaron los siguientes hallazgos principales:

* **Modelo Óptimo:** El modelo **Dual-Slope (DS)** presentó el mejor ajuste a los datos experimentales con un RMSE global de **3.23 dB**.
* **Pérdida por Quiebre (Turn Loss):** Se cuantificó una atenuación discreta de **41.22 dB** debido a la difracción en la esquina de 90°.
* **Discrepancia con Estándares:** Se demostró que los modelos estándar **ITU-R** y **3GPP** subestiman la pérdida en la zona NLoS en más de **20 dB** para este tipo de geometría.
* **Impacto de la Altura:** Se identificó que la estabilidad del enlace varía críticamente con la altura del receptor debido al multitrayecto vertical.

---

## 📂 Estructura del Repositorio

El código está organizado siguiendo el flujo de trabajo de la metodología experimental:

```text
/
├── data/
│   ├── calibration/        # Patrones de radiación de antenas (.mat)
│   ├── raw/                # Datos crudos del analizador de espectro (muestras)
│   └── processed/          # Datos pre-procesados listos para análisis
│
├── src/
│   ├── 01_Preprocesamiento/
│   │   └── Procesamiento_Potencia_Equiespaciado_v1.m  # Sincronización y limpieza de datos crudos
│   │
│   ├── 02_Procesamiento_PathLoss/
│   │   └── Procesamiento_PL_con_Ganancia_v1.m         # Cálculo de PL con corrección de ganancia variable y Promedio de Lee
│   │
│   ├── 03_Modelos/
│   │   ├── modelo_CI.m                                # Ajuste del modelo Close-In (CI)
│   │   └── script_optimizacion_dual_slope.m           # Optimización numérica del modelo Dual-Slope (fminsearch)
│   │
│   └── 04_Analisis_y_Graficos/
│       ├── calculo_EPL_CDF.m                          # Análisis de Excess Path Loss y CDF
│       ├── comparacion_NLoS_distancias.m              # Impacto de la posición del Tx
│       └── comparacion_estandares.m                   # Comparativa vs. ITU-R y 3GPP
│
└── README.md
