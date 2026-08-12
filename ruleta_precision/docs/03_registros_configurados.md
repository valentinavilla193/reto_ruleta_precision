# 3. Registros configurados

> En registros modificados con lectura–modificación–escritura se indica la máscara o el campo final relevante, porque los demás bits se conservan.

## 3.1 RCC

Base RCC:

```text
0x40023800
```

| Registro | Base | Offset | Dirección | Valor/máscara aplicada | Justificación |
|---|---|---:|---|---|---|
| `RCC_CR` | `0x40023800` | `0x00` | `0x40023800` | `OR 0x00000001` | Coloca `HSION=1` para habilitar HSI |
| `RCC_CFGR` | `0x40023800` | `0x08` | `0x40023808` | `0x00000000` | Selecciona HSI y divisiones por 1 en los campos utilizados |
| `RCC_AHB1ENR` | `0x40023800` | `0x30` | `0x40023830` | `OR 0x00000009` | Habilita GPIOA (bit 0) y GPIOD (bit 3) |

`0x09` en binario:

```text
0000 1001
```

## 3.2 GPIOA

Base GPIOA:

```text
0x40020000
```

| Registro | Base | Offset | Dirección | Campo final | Justificación |
|---|---|---:|---|---|---|
| `GPIOA_MODER` | `0x40020000` | `0x00` | `0x40020000` | bits `1:0 = 00` | PA0 como entrada |
| `GPIOA_PUPDR` | `0x40020000` | `0x0C` | `0x4002000C` | bits `1:0 = 10` | Pull-down de PA0 |
| `GPIOA_IDR` | `0x40020000` | `0x10` | `0x40020010` | solo lectura | Lee el estado de `WK_UP` en el bit 0 |

Para PA0:

```text
MODER0 = 00 -> entrada
PUPDR0 = 10 -> pull-down
```

## 3.3 GPIOD

Base GPIOD:

```text
0x40020C00
```

| Registro | Base | Offset | Dirección | Valor final/asignado | Justificación |
|---|---|---:|---|---|---|
| `GPIOD_MODER` | `0x40020C00` | `0x00` | `0x40020C00` | `0x55550000` | PD8–PD15 como salidas (`01` por pin) |
| `GPIOD_OTYPER` | `0x40020C00` | `0x04` | `0x40020C04` | `0x00000000` | Salidas push-pull |
| `GPIOD_OSPEEDR` | `0x40020C00` | `0x08` | `0x40020C08` | `0x00000000` | Velocidad baja |
| `GPIOD_PUPDR` | `0x40020C00` | `0x0C` | `0x40020C0C` | `0x00000000` | Sin pull-up/pull-down en las salidas |
| `GPIOD_BSRR` | `0x40020C00` | `0x18` | `0x40020C18` | variable | Apaga PD8–PD15 y enciende solamente el LED seleccionado |

### Valor `0x55550000`

Cada GPIO utiliza dos bits en MODER:

```text
00 -> entrada
01 -> salida
10 -> función alternativa
11 -> analógico
```

Para PD8–PD15 se repite `01` ocho veces:

```text
0101 0101 0101 0101 0000 0000 0000 0000
= 0x55550000
```

### Uso de BSRR

Para apagar todos los LEDs:

```text
0xFF000000
```

activa los bits de reset correspondientes a PD8–PD15.

Para encender un solo LED, una máscara `0x01…0x80` se desplaza 8 posiciones y se escribe en los bits de set de PD8–PD15.

## 3.4 SysTick

Base tomada para SysTick:

```text
0xE000E010
```

| Registro | Base | Offset | Dirección | Valor final | Justificación |
|---|---|---:|---|---|---|
| `SYST_CSR` | `0xE000E010` | `0x00` | `0xE000E010` | `0x00000005` | ENABLE=1, TICKINT=0, CLKSOURCE=1 |
| `SYST_RVR` | `0xE000E010` | `0x04` | `0xE000E014` | `0x00003E7F` | Recarga de 15 999 para 1 ms |
| `SYST_CVR` | `0xE000E010` | `0x08` | `0xE000E018` | `0x00000000` | Reinicia el valor actual |

La máscara usada para consultar `COUNTFLAG` es:

```text
0x00010000
```
