# Prompts utilizados durante el desarrollo del reto

> **Nota:** Estos prompts están organizados a partir del proceso de desarrollo de la práctica. Reflejan los conceptos trabajados durante el reto y el uso de material de apoyo como la *cheat sheet* de ARM/Thumb-2, el mapa de registros del STM32F407 y la documentación de GPIO y SysTick.

## Prompt 1 — Planeación bare-metal

Tengo que implementar una "Ruleta de Precisión" en un STM32F407VET6 usando únicamente ensamblador ARM Thumb-2 y acceso directo a registros. Ya revisé la cheat sheet y quiero limitarme a instrucciones sencillas como `LDR`, `STR`, `MOV`, `CMP`, `B`, `BL`, `BX`, `AND`, `ORR`, `BIC`, `TST` y desplazamientos lógicos.

Ayúdame a dividir el problema en bloques simples: configuración de reloj, GPIO de salida para 8 LEDs, entrada para pulsador, SysTick en polling, barrido, debouncing y evaluación de acierto/fallo. No uses HAL, CMSIS-Driver ni retardos con NOP.

## Prompt 2 — RCC y GPIO a nivel de registros

Quiero configurar directamente los registros del STM32F407. Según lo que he estudiado, primero debo habilitar el reloj de los puertos en `RCC_AHB1ENR` y después configurar `MODER`, `OTYPER`, `OSPEEDR` y `PUPDR`.

Voy a utilizar `PD8` hasta `PD15` como salidas y `PA0` como entrada para el pulsador `WK_UP`. Explícame qué bits debo modificar en cada registro, qué máscaras hexadecimales puedo usar y por qué. Quiero entender cómo se obtiene, por ejemplo, el patrón `0x55550000` para configurar PD8–PD15 como salidas.

## Prompt 3 — Uso de una fila de la matriz 1088AS

El profesor indicó usar una matriz 1088AS, pero para este reto solo voy a utilizar una fila de 8 LEDs. Quiero evitar multiplexación y controlar cada punto directamente desde `PD8` hasta `PD15`.

Ayúdame a plantear la conexión de una sola fila, identificando los ocho pines de columnas de la 1088AS y el pin común de la fila seleccionada. La idea es que cada GPIO controle un único LED y que solo haya un LED encendido a la vez.

## Prompt 4 — Barrido con máscaras y LSLS

Quiero implementar el barrido sin escribir ocho casos diferentes. Según la cheat sheet, puedo usar un desplazamiento lógico a la izquierda con `LSLS`.

Quiero representar la posición actual así:

- `0x01 -> LED1`
- `0x02 -> LED2`
- `0x04 -> LED3`
- `0x08 -> LED4`
- `0x10 -> LED5`
- `0x20 -> LED6`
- `0x40 -> LED7`
- `0x80 -> LED8`

Muéstrame cómo usar un registro, por ejemplo `R4`, para guardar esa máscara y cómo volver a `0x01` después de `0x80`. Explícalo con operaciones de bits, no con código de alto nivel.

## Prompt 5 — Control de un único LED con BSRR

Quiero usar `GPIOD_BSRR` en lugar de escribir directamente todo el puerto. Entiendo que los bits 0–15 del BSRR colocan pines en HIGH y los bits 16–31 los colocan en LOW.

Mis LEDs están en `PD8–PD15` y la lógica final del montaje es:

- `GPIO = 1 -> LED encendido`
- `GPIO = 0 -> LED apagado`

Explícame cómo apagar primero PD8–PD15 y luego encender únicamente el LED indicado por una máscara de `0x01` a `0x80`. Quiero entender por qué hay que desplazar la máscara 8 posiciones.

## Prompt 6 — Cálculo de SysTick a 1 ms

Voy a usar HSI a 16 MHz y SysTick en modo polling, sin interrupciones. Quiero una base de tiempo de 1 ms.

Ayúdame a desarrollar matemáticamente el valor de recarga de SysTick partiendo de `fCPU = 16 000 000 Hz` y `T = 1 ms`. Quiero justificar por qué el valor final es `LOAD = 15999` y cómo se representa en hexadecimal. También explícame qué significan `ENABLE`, `TICKINT`, `CLKSOURCE` y `COUNTFLAG` en `SYST_CSR`.

## Prompt 7 — Polling de SysTick

La práctica prohíbe retardos basados en ciclos de instrucciones. Quiero esperar usando exclusivamente SysTick.

Con base en la cheat sheet de Thumb-2, quiero hacerlo con instrucciones simples como `LDR`, `TST` y `BEQ`. Ayúdame a crear una rutina `esperar_1ms` que consulte el bit `COUNTFLAG` de `SYST_CSR` mediante polling y regrese con `BX LR` cuando haya transcurrido un periodo.

Explícame por qué esto sí es temporización por hardware y no un delay por decremento arbitrario.

## Prompt 8 — Debouncing de WK_UP en PA0

El pulsador integrado `WK_UP` está conectado a `PA0`. Quiero leerlo directamente desde `GPIOA_IDR`, usando el bit 0, y configurarlo como entrada con pull-down.

Para el antirrebote quiero tomar 20 muestras consecutivas separadas por 1 ms usando SysTick. Si alguna lectura vuelve a cero, la pulsación debe descartarse.

Ayúdame a implementar esta estrategia en Thumb-2 usando un registro como contador y solamente instrucciones básicas de la cheat sheet. También explícame por qué 20 muestras de 1 ms corresponden a 20 ms de debouncing.

## Prompt 9 — Evaluación de acierto y fallo

El LED objetivo será el cuarto, por lo tanto su máscara es `0x08`. La posición actual está guardada en `R4`.

Quiero evaluar la jugada usando `CMP` y saltos condicionales. Si `R4 == 0x08`, el LED objetivo debe parpadear tres veces. Si no coincide, el LED incorrecto debe permanecer fijo durante 2 segundos y después la ruleta debe reiniciar.

Ayúdame a estructurar esta lógica usando etiquetas y saltos Thumb-2 de forma sencilla y fácil de explicar en una sustentación.

## Prompt 10 — Revisión técnica del código final

Revisa mi código final de la Ruleta de Precisión pensando en una sustentación oral. No quiero que lo reescribas con técnicas más avanzadas.

Quiero que verifiques únicamente:

- acceso bare-metal a RCC, GPIO y SysTick;
- uso de `PD8–PD15` como salidas;
- uso de `PA0/WK_UP` como entrada;
- SysTick de 1 ms en polling;
- barrido mediante una máscara one-hot y `LSLS`;
- solo un LED encendido a la vez;
- debouncing de 20 ms;
- objetivo en `0x08`;
- fallo congelado 2 s;
- tres parpadeos en caso de acierto.

Después explícame qué hacen las instrucciones más importantes (`LDR`, `STR`, `ORR`, `BIC`, `AND`, `TST`, `CMP`, `LSLS`, `BL`, `BX LR`, `PUSH` y `POP`) dentro de este programa.

## Prompt 11 — Tabla de registros para GitHub

Necesito documentar los registros que modifiqué en el proyecto. Ya tengo identificados `RCC_CR`, `RCC_CFGR`, `RCC_AHB1ENR`, `GPIOA_MODER`, `GPIOA_PUPDR`, `GPIOA_IDR`, `GPIOD_MODER`, `GPIOD_OTYPER`, `GPIOD_OSPEEDR`, `GPIOD_PUPDR`, `GPIOD_BSRR`, `SYST_CSR`, `SYST_RVR` y `SYST_CVR`.

Organízalos en una tabla con dirección base, offset, dirección final, valor hexadecimal/máscara o campo configurado y justificación técnica. No agregues periféricos que no aparezcan en el código.

## Prompt 12 — Diagrama de flujo

Ayúdame a construir un diagrama de flujo del programa final que muestre únicamente la lógica implementada:

1. inicialización de HSI;
2. configuración de GPIO;
3. configuración de SysTick;
4. inicio en LED1;
5. espera de 1 ms;
6. incremento del contador;
7. lectura de WK_UP;
8. debouncing;
9. cambio de LED cada 120 ms;
10. evaluación de `R4 == 0x08`;
11. acierto con tres parpadeos;
12. fallo con congelamiento de 2 s y reinicio.

Quiero el diagrama en Mermaid para colocarlo directamente en GitHub.
