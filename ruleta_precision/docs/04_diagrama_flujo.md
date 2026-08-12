# 4. Diagrama de flujo lógico

```mermaid
flowchart TD
    A[Inicio] --> B[Configurar HSI a 16 MHz]
    B --> C[Configurar GPIOA y GPIOD]
    C --> D[Configurar SysTick a 1 ms]
    D --> E[Inicializar R4 = 0x01 y R5 = 0]
    E --> F[Mostrar LED actual]
    F --> G[Esperar 1 ms con COUNTFLAG]
    G --> H[Incrementar R5]
    H --> I[Leer WK_UP en PA0]
    I --> J{PA0 = 1?}

    J -- No --> K{R5 < 120?}
    K -- Sí --> G
    K -- No --> L[R5 = 0]
    L --> M{R4 = 0x80?}
    M -- Sí --> N[R4 = 0x01]
    M -- No --> O[LSLS R4, R4, #1]
    N --> F
    O --> F

    J -- Sí --> P[Antirrebote: 20 lecturas de 1 ms]
    P --> Q{Pulsación válida?}
    Q -- No --> G
    Q -- Sí --> R{R4 = 0x08?}

    R -- Sí --> S[Parpadear LED objetivo 3 veces]
    S --> T[Fin: permanecer detenido]

    R -- No --> U[Mantener LED incorrecto 2 s]
    U --> V[Esperar liberación de WK_UP]
    V --> E
```

## Resumen del flujo

- La inicialización configura reloj, GPIO y SysTick.
- El barrido se controla mediante `R4`.
- `R5` determina cuándo transcurrieron 120 ms.
- El pulsador se lee continuamente.
- La pulsación se valida durante 20 ms.
- `R4 = 0x08` significa acierto.
- Cualquier otro valor significa fallo.
