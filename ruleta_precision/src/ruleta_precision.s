        .syntax unified
        .cpu cortex-m4
        .thumb

        .global _start
        .text


/* ============================================================
   RULETA DE PRECISION - STM32F407VET6 BLACK

   MATRIZ 1088AS:
   Se utiliza una sola FILA de 8 LEDs.

   CATODO COMUN:
   Fila 4, pin 12 -> resistencia 330 ohm -> GND

   ANODOS:
   C1 pin 13 -> PD8
   C2 pin 3  -> PD9
   C3 pin 4  -> PD10
   C4 pin 10 -> PD11    OBJETIVO
   C5 pin 6  -> PD12
   C6 pin 11 -> PD13
   C7 pin 15 -> PD14
   C8 pin 16 -> PD15

   PULSADOR:
   WK_UP integrado -> PA0

   LOGICA:
   GPIO = 1 -> LED encendido
   GPIO = 0 -> LED apagado
   ============================================================ */


/* ================= RCC ================= */

        .equ RCC_CR,          0x40023800
        .equ RCC_CFGR,        0x40023808
        .equ RCC_AHB1ENR,     0x40023830


/* ================= GPIOA ================= */

        .equ GPIOA_MODER,     0x40020000
        .equ GPIOA_PUPDR,     0x4002000C
        .equ GPIOA_IDR,       0x40020010


/* ================= GPIOD ================= */

        .equ GPIOD_MODER,     0x40020C00
        .equ GPIOD_OTYPER,    0x40020C04
        .equ GPIOD_OSPEEDR,   0x40020C08
        .equ GPIOD_PUPDR,     0x40020C0C
        .equ GPIOD_BSRR,      0x40020C18


/* ================= SYSTICK ================= */

        .equ SYST_CSR,        0xE000E010
        .equ SYST_RVR,        0xE000E014
        .equ SYST_CVR,        0xE000E018


/* ================= CONSTANTES ================= */

        .equ LED_OBJETIVO,    0x08
        .equ TIEMPO_LED,      120
        .equ ANTIRREBOTE,     20
        .equ TIEMPO_ERROR,    2000
        .equ TIEMPO_PARPADEO, 200


/* ============================================================
   INICIO
   ============================================================ */

        .thumb_func
_start:

        bl      configurar_reloj
        bl      configurar_gpio
        bl      configurar_systick


/* ============================================================
   INICIAR O REINICIAR JUEGO
   ============================================================ */

reiniciar_juego:

        /*
        r4 = LED actual
        r5 = contador de tiempo
        */

        movs    r4, #1
        movs    r5, #0


        /* Encender LED1 */

        mov     r0, r4
        bl      mostrar_led


/* ============================================================
   CICLO PRINCIPAL
   ============================================================ */

ciclo_principal:

        /* Esperar 1 ms */

        bl      esperar_1ms


        /* Contar tiempo */

        adds    r5, r5, #1


        /* Leer WK_UP */

        bl      leer_pulsador


        /* ¿Boton presionado? */

        cmp     r0, #1
        beq     revisar_pulsacion


        /* ¿Ya pasaron 120 ms? */

        cmp     r5, #TIEMPO_LED
        blo     ciclo_principal


        /* Reiniciar contador */

        movs    r5, #0


/* ============================================================
   PASAR AL SIGUIENTE LED
   ============================================================ */

        /* ¿Estamos en LED8? */

        cmp     r4, #0x80
        beq     volver_led1


        /*
        Mover el bit una posicion.

        00000001
        00000010
        00000100
        00001000
        ...
        */

        lsls    r4, r4, #1

        b       mostrar_siguiente


volver_led1:

        movs    r4, #1


mostrar_siguiente:

        mov     r0, r4

        bl      mostrar_led

        b       ciclo_principal


/* ============================================================
   REVISAR PULSACION
   ============================================================ */

revisar_pulsacion:

        /* Aplicar antirrebote */

        bl      antirrebote


        /* Si no fue valida, continuar */

        cmp     r0, #1
        bne     ciclo_principal


        /* Comparar LED actual con LED4 */

        cmp     r4, #LED_OBJETIVO
        beq     acierto


        /* Si no coincide */

        b       fallo


/* ============================================================
   FALLO
   ============================================================ */

fallo:

        /*
        No cambiamos el LED.
        El LED incorrecto queda encendido
        durante 2 segundos.
        */

        ldr     r0, =TIEMPO_ERROR

        bl      esperar_ms


/* Esperar que se suelte WK_UP */

esperar_liberacion:

        bl      esperar_1ms

        bl      leer_pulsador

        cmp     r0, #1
        beq     esperar_liberacion


        /* Reiniciar juego */

        b       reiniciar_juego


/* ============================================================
   ACIERTO
   ============================================================ */

acierto:

        /* Hacer tres parpadeos */

        movs    r7, #3


parpadear:

        /* Apagar todos */

        movs    r0, #0

        bl      mostrar_led


        /* Esperar 200 ms */

        movs    r0, #TIEMPO_PARPADEO

        bl      esperar_ms


        /* Encender LED objetivo */

        movs    r0, #LED_OBJETIVO

        bl      mostrar_led


        /* Esperar 200 ms */

        movs    r0, #TIEMPO_PARPADEO

        bl      esperar_ms


        /* Restar un parpadeo */

        subs    r7, r7, #1

        bne     parpadear


/* ============================================================
   FIN DEL JUEGO
   ============================================================ */

fin_juego:

        /*
        Despues de acertar el juego
        queda detenido.
        */

        b       fin_juego


/* ============================================================
   CONFIGURAR RELOJ HSI = 16 MHz
   ============================================================ */

configurar_reloj:

        /*
        RCC_CR bit 0 = HSION
        Encender HSI.
        */

        ldr     r1, =RCC_CR

        ldr     r0, [r1]

        orr     r0, r0, #1

        str     r0, [r1]


/* Esperar que HSI este listo */

esperar_hsi:

        ldr     r0, [r1]


        /*
        RCC_CR bit 1 = HSIRDY
        */

        tst     r0, #2

        beq     esperar_hsi


        /*
        Seleccionar HSI como reloj.
        */

        ldr     r1, =RCC_CFGR

        movs    r0, #0

        str     r0, [r1]


/* Confirmar HSI */

esperar_reloj:

        ldr     r0, [r1]

        tst     r0, #0x0C

        bne     esperar_reloj

        bx      lr


/* ============================================================
   CONFIGURAR GPIO
   ============================================================ */

configurar_gpio:

        /*
        RCC_AHB1ENR:

        bit 0 = GPIOA
        bit 3 = GPIOD

        0x09 = 00001001
        */

        ldr     r1, =RCC_AHB1ENR

        ldr     r0, [r1]

        orr     r0, r0, #0x09

        str     r0, [r1]


        /* Lectura de seguridad */

        ldr     r0, [r1]


/* ============================================================
   PD8 - PD15 COMO SALIDAS
   ============================================================ */

        /*
        Primero apagar todos los LEDs.

        LOW = LED apagado.

        Bits 24-31 de BSRR ponen
        PD8-PD15 en LOW.
        */

        ldr     r1, =GPIOD_BSRR

        ldr     r0, =0xFF000000

        str     r0, [r1]


        /*
        PD8-PD15 como salidas.

        01 = salida.

        Valor:
        0x55550000
        */

        ldr     r1, =GPIOD_MODER

        ldr     r0, =0x55550000

        str     r0, [r1]


        /* Salidas push-pull */

        ldr     r1, =GPIOD_OTYPER

        movs    r0, #0

        str     r0, [r1]


        /* Velocidad baja */

        ldr     r1, =GPIOD_OSPEEDR

        movs    r0, #0

        str     r0, [r1]


        /* Sin pull-up ni pull-down */

        ldr     r1, =GPIOD_PUPDR

        movs    r0, #0

        str     r0, [r1]


/* ============================================================
   PA0 COMO ENTRADA - WK_UP
   ============================================================ */

        /*
        PA0 utiliza bits 1:0 de MODER.

        00 = entrada
        */

        ldr     r1, =GPIOA_MODER

        ldr     r0, [r1]

        bic     r0, r0, #0x03

        str     r0, [r1]


/* ============================================================
   PULL-DOWN EN PA0
   ============================================================ */

        /*
        PA0 PUPDR:

        00 = ninguno
        01 = pull-up
        10 = pull-down
        */

        ldr     r1, =GPIOA_PUPDR

        ldr     r0, [r1]


        /* Limpiar bits 1:0 */

        bic     r0, r0, #0x03


        /* Colocar 10 = pull-down */

        orr     r0, r0, #0x02

        str     r0, [r1]

        bx      lr


/* ============================================================
   CONFIGURAR SYSTICK
   ============================================================ */

configurar_systick:

        /*
        HSI = 16 MHz

        Queremos 1 ms.

        16 000 000 x 0.001 = 16 000

        LOAD = 16 000 - 1

        LOAD = 15 999
        */


        /* Desactivar SysTick */

        ldr     r1, =SYST_CSR

        movs    r0, #0

        str     r0, [r1]


        /* Valor de recarga */

        ldr     r1, =SYST_RVR

        ldr     r0, =15999

        str     r0, [r1]


        /* Limpiar contador */

        ldr     r1, =SYST_CVR

        movs    r0, #0

        str     r0, [r1]


        /*
        SYST_CSR = 5

        ENABLE    = 1
        TICKINT   = 0
        CLKSOURCE = 1
        */

        ldr     r1, =SYST_CSR

        movs    r0, #5

        str     r0, [r1]

        bx      lr


/* ============================================================
   ESPERAR 1 ms MEDIANTE POLLING
   ============================================================ */

esperar_1ms:

        ldr     r1, =SYST_CSR


        /*
        COUNTFLAG = bit 16
        */

        ldr     r2, =0x00010000


esperar_bandera:

        ldr     r0, [r1]

        tst     r0, r2

        beq     esperar_bandera

        bx      lr


/* ============================================================
   ESPERAR VARIOS MILISEGUNDOS

   r0 = numero de milisegundos
   ============================================================ */

esperar_ms:

        /*
        Guardamos r4 y lr.
        */

        push    {r4, lr}

        mov     r4, r0


ciclo_espera:

        cmp     r4, #0

        beq     terminar_espera


        /* Esperar 1 ms */

        bl      esperar_1ms


        /* Restar un milisegundo */

        subs    r4, r4, #1

        b       ciclo_espera


terminar_espera:

        pop     {r4, pc}


/* ============================================================
   LEER WK_UP EN PA0
   ============================================================ */

leer_pulsador:

        /*
        Leer GPIOA_IDR.
        */

        ldr     r1, =GPIOA_IDR

        ldr     r0, [r1]


        /*
        PA0 corresponde al bit 0.

        AND con 1 elimina todos
        los demas bits.
        */

        and     r0, r0, #1


        /*
        r0 = 0 -> no presionado
        r0 = 1 -> presionado
        */

        bx      lr


/* ============================================================
   ANTIRREBOTE
   ============================================================ */

antirrebote:

        /*
        El boton debe permanecer en 1
        durante 20 lecturas consecutivas.

        Cada lectura esta separada por 1 ms.
        */

        push    {r3, lr}

        movs    r3, #ANTIRREBOTE


comprobar_boton:

        /* Esperar 1 ms */

        bl      esperar_1ms


        /* Leer PA0 */

        bl      leer_pulsador


        /* ¿Sigue presionado? */

        cmp     r0, #1

        bne     pulsacion_falsa


        /* Restar una muestra */

        subs    r3, r3, #1

        bne     comprobar_boton


        /* Pulsacion valida */

        movs    r0, #1

        pop     {r3, pc}


pulsacion_falsa:

        movs    r0, #0

        pop     {r3, pc}


/* ============================================================
   MOSTRAR SOLAMENTE UN LED

   LOGICA:

   HIGH = LED encendido
   LOW  = LED apagado

   r0:

   0x01 = PD8  = LED1
   0x02 = PD9  = LED2
   0x04 = PD10 = LED3
   0x08 = PD11 = LED4 OBJETIVO
   0x10 = PD12 = LED5
   0x20 = PD13 = LED6
   0x40 = PD14 = LED7
   0x80 = PD15 = LED8
   ============================================================ */

mostrar_led:

        ldr     r1, =GPIOD_BSRR


        /*
        PRIMERO APAGAR TODOS.

        Bits 24-31 del BSRR ponen:

        PD8-PD15 = LOW

        LOW = apagado.
        */

        ldr     r2, =0xFF000000

        str     r2, [r1]


        /*
        Ahora encender solamente uno.

        r0 comienza usando bits 0-7.

        Debemos moverlos hacia PD8-PD15:

        bit 0 -> PD8
        bit 1 -> PD9
        bit 2 -> PD10
        bit 3 -> PD11
        bit 4 -> PD12
        bit 5 -> PD13
        bit 6 -> PD14
        bit 7 -> PD15

        Por eso desplazamos 8 posiciones.
        */

        lsls    r0, r0, #8


        /*
        Bits 8-15 del BSRR ponen
        el GPIO correspondiente en HIGH.

        Como r0 solo tiene un bit en 1,
        solamente un LED se enciende.
        */

        str     r0, [r1]

        bx      lr