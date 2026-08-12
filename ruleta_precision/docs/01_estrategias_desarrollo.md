# 1. Estrategias de desarrollo

## 1.1 Representación del LED actual

El programa representa los ocho LEDs mediante una máscara *one-hot* almacenada en `R4`. Solo existe un bit en `1`:

| LED | Binario | Hexadecimal |
|---|---|---|
| LED 1 | `00000001` | `0x01` |
| LED 2 | `00000010` | `0x02` |
| LED 3 | `00000100` | `0x04` |
| LED 4 — objetivo | `00001000` | `0x08` |
| LED 5 | `00010000` | `0x10` |
| LED 6 | `00100000` | `0x20` |
| LED 7 | `01000000` | `0x40` |
| LED 8 | `10000000` | `0x80` |

El cambio de posición se realiza mediante:

```asm
lsls r4, r4, #1
```

Así se evita crear ocho casos separados. Cuando `R4 = 0x80`, el programa vuelve a `0x01`.

## 1.2 Mantener un solo LED encendido

La subrutina `mostrar_led` usa `GPIOD_BSRR`.

Primero apaga todos los LEDs:

```asm
ldr r2, =0xFF000000
str r2, [r1]
```

Los bits 24–31 del BSRR ponen PD8–PD15 en `LOW`.

Luego la máscara lógica se desplaza ocho posiciones:

```asm
lsls r0, r0, #8
```

y se escribe nuevamente en BSRR. Como la máscara contiene un solo `1`, solamente un GPIO entre PD8 y PD15 queda en `HIGH`.

## 1.3 Velocidad del barrido

SysTick proporciona una referencia de 1 ms. `R5` cuenta estos periodos:

```asm
bl   esperar_1ms
adds r5, r5, #1
```

Cuando `R5` llega a 120, se selecciona el siguiente LED. Por tanto, cada LED permanece aproximadamente 120 ms encendido.

## 1.4 Lectura del pulsador

Se utiliza el pulsador integrado `WK_UP`, conectado a `PA0`. El programa lee el bit 0 de `GPIOA_IDR`:

```asm
ldr r1, =GPIOA_IDR
ldr r0, [r1]
and r0, r0, #1
```

Resultado:

```text
0 -> no presionado
1 -> presionado
```

## 1.5 Debouncing

Una pulsación no se acepta con una única lectura. Después de detectar un `1`, la subrutina `antirrebote` exige 20 lecturas consecutivas separadas por 1 ms.

```text
20 muestras × 1 ms = 20 ms
```

Si alguna lectura vuelve a `0`, la pulsación se considera falsa.

## 1.6 Acierto

El objetivo se representa por:

```asm
.equ LED_OBJETIVO, 0x08
```

La evaluación se realiza con:

```asm
cmp r4, #LED_OBJETIVO
beq acierto
```

Si coincide, el LED objetivo se apaga y enciende tres veces usando `R7` como contador.

## 1.7 Fallo

Si `R4` no coincide con `0x08`, el programa no modifica el LED actual y llama:

```asm
ldr r0, =TIEMPO_ERROR
bl  esperar_ms
```

`TIEMPO_ERROR = 2000`, de modo que el LED incorrecto queda visible durante 2 s. Después se espera a que el usuario libere `WK_UP` y se reinicia la secuencia.
