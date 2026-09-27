# Ruleta de Precisión — STM32F407VET6

Firmware bare-metal en ensamblador ARM Thumb-2 para implementar una ruleta visual con una fila de 8 LEDs de una matriz 1088AS y el pulsador integrado `WK_UP` de la tarjeta STM32F407VET6 Black.

## Estructura del repositorio

```text
ruleta_precision_github/
├── README.md
├── src/
│   └── ruleta_precision.s
├── docs/
│    ├── 01_estrategias_desarrollo.md
│    ├── 02_calculos_systick.md
│    ├── 03_registros_configurados.md
│    ├── 04_diagrama_flujo.md
│    ├── 05_hardware_y_pines.md
│    └──  06_explicacion_codigo.md
│   
└── prompts
```

## Hardware utilizado

- STM32F407VET6 Black.
- Matriz LED 1088AS.
- Una fila de 8 LEDs de la matriz.
- Resistencia de 330 Ω en el cátodo común de la fila utilizada.
- Pulsador `WK_UP` integrado, conectado a `PA0`.

## Asignación principal

| Elemento | STM32 | Matriz 1088AS |
|---|---|---|
| LED 1 | PD8 | C1, pin 13 |
| LED 2 | PD9 | C2, pin 3 |
| LED 3 | PD10 | C3, pin 4 |
| **LED 4 — objetivo** | **PD11** | **C4, pin 10** |
| LED 5 | PD12 | C5, pin 6 |
| LED 6 | PD13 | C6, pin 11 |
| LED 7 | PD14 | C7, pin 15 |
| LED 8 | PD15 | C8, pin 16 |
| Cátodo común de la fila | GND mediante 330 Ω | Fila 4, pin 12 |
| Pulsador | PA0 | `WK_UP` integrado |

La lógica usada por el firmware es:

```text
GPIO = 1 -> LED encendido
GPIO = 0 -> LED apagado
```

## Funcionamiento

1. Se configura el HSI a 16 MHz.
2. Se habilitan GPIOA y GPIOD.
3. PD8–PD15 se configuran como salidas.
4. PA0 se configura como entrada con pull-down para leer `WK_UP`.
5. SysTick genera una base temporal de 1 ms en modo polling.
6. Un único bit en `R4` representa el LED actual.
7. Cada 120 ms la máscara se desplaza una posición.
8. Al presionar `WK_UP`, se realiza un antirrebote de 20 ms.
9. Si el LED actual es el cuarto (`0x08`), el objetivo parpadea tres veces.
10. Si no coincide, el LED incorrecto se mantiene durante 2 s y el juego reinicia.

## Documentación exigida por la rúbrica

- [Estrategias de desarrollo](docs/01_estrategias_desarrollo.md)
- [Cálculos de temporización con SysTick](docs/02_calculos_systick.md)
- [Tabla de registros configurados](docs/03_registros_configurados.md)
- [Diagrama de flujo lógico](docs/04_diagrama_flujo.md)
- [Diagrama de bloques de hardware y asignación de pines](docs/05_hardware_y_pines.md)
- [Explicación detallada del código](docs/06_explicacion_codigo.md)
- [Carpeta para evidencias reales](docs/evidencias/README.md)

## Código fuente

El firmware se encuentra en:

```text
src/ruleta_precision.s
```

Está estructurado por bloques y comentado para explicar la función de los registros, las máscaras y las subrutinas.
