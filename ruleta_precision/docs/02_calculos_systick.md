# 2. Cálculos de temporización — SysTick

## 2.1 Frecuencia seleccionada

El firmware selecciona el oscilador interno HSI:

```text
fCPU = 16 MHz = 16 000 000 Hz
```

Se requiere una base temporal de:

```text
Ttick = 1 ms = 0.001 s
```

## 2.2 Número de ciclos

La cantidad de ciclos necesarios para 1 ms es:

```text
N = fCPU × Ttick
N = 16 000 000 × 0.001
N = 16 000 ciclos
```

SysTick cuenta desde el valor cargado en `LOAD` hasta cero, por lo que:

```text
LOAD = N - 1
LOAD = 16 000 - 1
LOAD = 15 999
```

Conversión a hexadecimal:

```text
15 999 = 0x3E7F
```

Por eso el código carga:

```asm
ldr r1, =SYST_RVR
ldr r0, =15999
str r0, [r1]
```

## 2.3 Configuración de SYST_CSR

Se escribe:

```text
SYST_CSR = 0x05 = 0000 0101b
```

| Bit | Campo | Valor | Función |
|---:|---|---:|---|
| 0 | ENABLE | 1 | Habilita SysTick |
| 1 | TICKINT | 0 | No genera interrupciones |
| 2 | CLKSOURCE | 1 | Usa el reloj del procesador |

El programa trabaja por **polling**, consultando `COUNTFLAG` (bit 16).

## 2.4 Barrido

```text
TIEMPO_LED = 120
120 ticks × 1 ms = 120 ms
```

## 2.5 Antirrebote

```text
ANTIRREBOTE = 20
20 muestras × 1 ms = 20 ms
```

## 2.6 Fallo

```text
TIEMPO_ERROR = 2000
2000 ticks × 1 ms = 2000 ms = 2 s
```

## 2.7 Parpadeo de acierto

```text
TIEMPO_PARPADEO = 200
200 ticks × 1 ms = 200 ms
```

Cada parpadeo contiene 200 ms apagado y 200 ms encendido. Se repite tres veces.
