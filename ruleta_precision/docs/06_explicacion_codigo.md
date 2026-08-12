# 6. Explicación detallada del código

Este documento sirve como apoyo para la sustentación técnica.

## 6.1 Directivas iniciales

```asm
.syntax unified
.cpu cortex-m4
.thumb
.global _start
.text
```

- `.syntax unified`: selecciona la sintaxis unificada de ARM.
- `.cpu cortex-m4`: indica el núcleo utilizado.
- `.thumb`: utiliza el conjunto de instrucciones Thumb/Thumb-2.
- `.global _start`: exporta el punto de entrada.
- `.text`: comienza la sección de código.

## 6.2 Registros de propósito general usados

| Registro | Uso en el programa |
|---|---|
| R0 | Parámetros, valores temporales y retorno de subrutinas |
| R1 | Dirección de registros de periféricos |
| R2 | Máscaras auxiliares |
| R3 | Contador del antirrebote |
| R4 | Máscara del LED actual |
| R5 | Contador de milisegundos del barrido |
| R7 | Contador de parpadeos |
| LR | Dirección de retorno de subrutinas |

## 6.3 Punto de entrada

```asm
_start:
    bl configurar_reloj
    bl configurar_gpio
    bl configurar_systick
```

`BL` llama una subrutina y almacena la dirección de retorno en `LR`. Las subrutinas terminan normalmente con:

```asm
bx lr
```

## 6.4 Estado inicial del juego

```asm
movs r4, #1
movs r5, #0
mov  r0, r4
bl   mostrar_led
```

- `R4 = 0x01`: selecciona LED1.
- `R5 = 0`: reinicia el tiempo acumulado.
- `R0` lleva la máscara a `mostrar_led`.

## 6.5 Ciclo principal

```asm
bl   esperar_1ms
adds r5, r5, #1
bl   leer_pulsador
```

Cada vuelta espera un periodo real de SysTick y suma 1 a `R5`.

Después se evalúa:

```asm
cmp r0, #1
beq revisar_pulsacion
```

Si el pulsador no está activo se verifica si se cumplieron 120 ms.

## 6.6 Barrido mediante desplazamiento

```asm
cmp  r4, #0x80
beq  volver_led1
lsls r4, r4, #1
```

`LSLS` desplaza el único bit activo:

```text
0x01 -> 0x02 -> 0x04 -> 0x08 -> 0x10 -> 0x20 -> 0x40 -> 0x80
```

Cuando llega a `0x80`, vuelve a `0x01`.

## 6.7 Control de un único LED

`mostrar_led` usa BSRR:

```asm
ldr r2, =0xFF000000
str r2, [r1]
```

Esto coloca PD8–PD15 en `LOW`, apagándolos.

Luego:

```asm
lsls r0, r0, #8
str  r0, [r1]
```

mueve la máscara a los bits físicos PD8–PD15 y enciende solamente el bit seleccionado.

Ejemplo para el objetivo:

```text
r0 = 0x08
0x08 << 8 = 0x0800
```

`0x0800` corresponde a PD11.

## 6.8 Reloj HSI

```asm
ldr r1, =RCC_CR
ldr r0, [r1]
orr r0, r0, #1
str r0, [r1]
```

`ORR #1` coloca `HSION=1`.

El programa espera `HSIRDY` mediante:

```asm
tst r0, #2
beq esperar_hsi
```

Después escribe `0` en `RCC_CFGR` para seleccionar HSI en los campos utilizados.

## 6.9 Habilitación de GPIO

```asm
orr r0, r0, #0x09
```

`0x09 = 00001001b`:

- bit 0: GPIOA.
- bit 3: GPIOD.

## 6.10 Configuración PD8–PD15

```asm
ldr r0, =0x55550000
str r0, [r1]
```

Cada pin usa dos bits en `MODER`. El patrón `01` significa salida. Ocho repeticiones sobre PD8–PD15 producen `0x55550000`.

`GPIOD_OTYPER = 0` selecciona push-pull.

`GPIOD_OSPEEDR = 0` selecciona velocidad baja.

`GPIOD_PUPDR = 0` desactiva resistencias internas en esos pines.

## 6.11 PA0 y WK_UP

PA0 usa los bits `1:0` de `MODER` y `PUPDR`.

```asm
bic r0, r0, #0x03
```

limpia los bits y deja `MODER0 = 00`, es decir, entrada.

Después:

```asm
bic r0, r0, #0x03
orr r0, r0, #0x02
```

deja `PUPDR0 = 10`, es decir, pull-down.

## 6.12 Lectura del pulsador

```asm
ldr r1, =GPIOA_IDR
ldr r0, [r1]
and r0, r0, #1
```

Como PA0 es el bit 0, `AND #1` descarta los demás bits.

Resultado:

```text
R0 = 0 -> no presionado
R0 = 1 -> presionado
```

## 6.13 Antirrebote

```asm
movs r3, #20
```

Se realizan 20 comprobaciones. Cada una hace:

```asm
bl esperar_1ms
bl leer_pulsador
cmp r0, #1
```

Si alguna muestra es `0`, se rechaza la pulsación. Si las 20 son `1`, se acepta.

## 6.14 SysTick

El cálculo produce:

```text
LOAD = 15 999 = 0x3E7F
```

El código escribe:

```asm
ldr r1, =SYST_RVR
ldr r0, =15999
str r0, [r1]
```

Luego:

```asm
movs r0, #5
```

configura:

```text
ENABLE = 1
TICKINT = 0
CLKSOURCE = 1
```

## 6.15 Polling de COUNTFLAG

```asm
ldr r2, =0x00010000
esperar_bandera:
    ldr r0, [r1]
    tst r0, r2
    beq esperar_bandera
```

El programa no genera una interrupción. Permanece consultando `COUNTFLAG` hasta que SysTick completa un periodo.

## 6.16 Evaluación de la jugada

```asm
cmp r4, #LED_OBJETIVO
beq acierto
b   fallo
```

`LED_OBJETIVO = 0x08`, por lo que la comparación verifica si está seleccionado PD11.

## 6.17 Fallo

Se llama:

```asm
ldr r0, =2000
bl esperar_ms
```

Durante esos 2 s no cambia el LED.

Después se espera la liberación del pulsador y se reinicia el juego.

## 6.18 Acierto

```asm
movs r7, #3
```

El ciclo apaga el objetivo 200 ms y lo enciende 200 ms. `R7` disminuye hasta cero. Después el programa entra en:

```asm
fin_juego:
    b fin_juego
```

y permanece detenido hasta un reinicio.

## 6.19 Instrucciones principales que se deben saber explicar

| Instrucción | Función |
|---|---|
| `LDR` | Cargar dato o dirección |
| `STR` | Escribir en memoria |
| `MOV/MOVS` | Copiar/cargar valor |
| `ORR` | Poner bits en 1 |
| `BIC` | Limpiar bits |
| `AND` | Filtrar bits |
| `TST` | Probar bits |
| `CMP` | Comparar |
| `LSLS` | Desplazamiento lógico a la izquierda |
| `ADDS` | Sumar |
| `SUBS` | Restar |
| `B` | Salto incondicional |
| `BEQ` | Saltar si igual |
| `BNE` | Saltar si diferente |
| `BLO` | Saltar si menor sin signo |
| `BL` | Llamar subrutina |
| `BX LR` | Retornar |
| `PUSH/POP` | Guardar/recuperar registros de la pila |
