;*******************************************************************************
;*
;*       Control basico del ADC
;*
;*******************************************************************************
;* FileName:        main.asm
;* Processor:       PIC16F887
;* Complier:        MPASM v5.77
;* Author:          Pedro Sánchez (MrChunckuee)
;* Blog:            http://mrchunckuee.blogspot.com/
;* Email:           mrchunckuee.psr@gmail.com
;* Description:     Controlar los 8 LEDs en el puerto D, dependiendo del nivel 
;*		    de voltaje en RA0.
;*******************************************************************************
;* Rev.         Date            Comment
;*  v1.0.0	15/06/2015      - Creación del firmware
;*  v1.0.1	11/10/2019	- Pruebas y revision del codigo, ademas se agrego 
;*				  los comentario en las lineas.
;*  v1.0.2	28/06/2025	- Cambios para usar el PIC-AS del compilador XC8
;*******************************************************************************

PROCESSOR 16F887

; PIC16F887 Configuration Bit Settings
; Assembly source line config statements
; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = OFF           ; Power-up Timer Enable bit (PWRT disabled)
  CONFIG  MCLRE = ON            ; RE3/MCLR pin function select bit (RE3/MCLR pin function is MCLR)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = ON            ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is enabled)
  CONFIG  LVP = OFF             ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming disabled)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)

// config statements should precede project file includes.
#include <xc.inc>

;********** V A R I A B L E S **************************************************
;objects in bank 0 memory
PSECT udata_bank0
RContadorA:  DS	    1	    ;reserve 1 byte
RContadorB:  DS     1
Valor_ADC:   DS	    1
    
;********** I N I C I O * D E * P R O G R A M A ********************************
PSECT resetVec,class=CODE,delta=2,abs
ORG 0x0000
RESETSys:
    PAGESEL    MCUInit                ;jump to the main routine
    GOTO       MCUInit

;********** C O F I G U R A * M C U ********************************************
PSECT mainVec,class=CODE,delta=2,abs
ORG 0x0006
MCUInit:
    BANKSEL ANSEL 
    MOVLW   0x01  
    MOVWF   BANKMASK(ANSEL)   ; use AN0
    
    BANKSEL OSCCON
    movlw   0x71    ;Cargo valor a w 
    movwf   BANKMASK(OSCCON)  ;Oscilador interno 8MHz --> IRCF<2:0> = 1, CCS = 1
    
    BANKSEL TRISD        
    MOVLW   0x00  
    MOVWF   BANKMASK(TRISD)   ;all PORTD outputs
    BANKSEL PORTD 
    CLRF    BANKMASK(PORTD)   ;Clear PORTD

;********** C O N F I G U R A * A D C ******************************************
ADC_Init:
    ;Se inicializa el registro ADCON1 del ADC
    BANKSEL ADCON1
    movlw   0x0E    ;Configura los canales para usar solo RA0/AN0 y
    movwf   BANKMASK(ADCON1)  ;selecciona la justificacion a la izquierda
    BANKSEL TRISA
    movlw   0x01 
    movwf   BANKMASK(TRISA)   ;Se coloca RA0 como entrada (analoga).
    BANKSEL PORTA   ;Selecciona el banco 0 nuevamente
    clrf    BANKMASK(PORTA)   ;Clear PORTA
    ;Se inicaliza ahora el registro ADCON0 del ADC. Notese que se usa
    ;el reloj interno del ADC debido a que la velocidad no es critica y
    ;la aplicacion no requiere exactitud en la velocidad de conversion.
    BANKSEL ADCON0
    movlw   0xC1	; Selecciona el reloj interno, selecciona tambien el
    movwf   BANKMASK(ADCON0)	; Canal cero del ADC (AN0) y activa el ADC.
    ;Nota: en caso de usar varios canales, puede modificarse este registro
    ;para intercambiarlos.
    clrf    Valor_ADC	;Limpia la variable

;********** L E C T U R A  *  A D C ********************************************
ADC_Read:
    bsf	    ADCON0, 1	    ; Inicia la conversion del ADC
    movlw   1		    ; Espera durante 1ms
    call    Retardo_ms
    btfsc   ADCON0, 1	    ; Espera a que la conversion termine por
    goto    $-1		    ; medio de verificar el mismo bit
    movf    ADRESH, W	    ; Toma el resultado del ADC y lo guarda
    movwf   Valor_ADC
    ;Nota: Dado que se utilizo la justificacion a la izquierda, se pueden
    ;tomar solo los 8 bits mas significativos y usarlos como resultado.
    ;Esto puede realizarse si solo se necesitan 8 bits de resolucion y no
    ;los 10 que provee el ADC.


;********** R U T I N A  *  L E D s ********************************************
; Cargamos un valor a W.
; Le restamos al ADC el valor de W.
; Comparamos si es <= ejecutamos siguiente linea, si > saltamos una linea.
; Actualizamos PORTD.
; REalizamos nuevamente una lectura.
    
Update_LED0:
    movlw   28
    SUBWF   Valor_ADC,W 
    BTFSC   STATUS,0
    GOTO    Update_LED1
    MOVLW   0b00000000
    MOVWF   PORTD
    GOTO    ADC_Read	; Volvemos a leer RA0

Update_LED1:
    movlw   56
    SUBWF   Valor_ADC,W
    BTFSC   STATUS,0
    GOTO    Update_LED2
    MOVLW   0b00000001
    MOVWF   PORTD
    GOTO    ADC_Read	; Volvemos a leer RA0

Update_LED2:
    movlw   84
    SUBWF   Valor_ADC,W
    BTFSC   STATUS,0
    GOTO    Update_LED3
    MOVLW   0b00000011
    MOVWF   PORTD
    GOTO    ADC_Read	; Volvemos a leer RA0

Update_LED3:
    movlw   112
    SUBWF   Valor_ADC,W
    BTFSC   STATUS,0
    GOTO    Update_LED4
    MOVLW   0b00000111
    MOVWF   PORTD
    GOTO    ADC_Read	; Volvemos a leer RA0

Update_LED4:
    movlw   140
    SUBWF   Valor_ADC,W
    BTFSC   STATUS,0
    GOTO    Update_LED5
    MOVLW   0b00001111
    MOVWF   PORTD
    GOTO    ADC_Read	; Volvemos a leer RA0
    
Update_LED5:
    movlw   168
    SUBWF   Valor_ADC,W
    BTFSC   STATUS,0
    GOTO    Update_LED6
    MOVLW   0b00011111
    MOVWF   PORTD
    GOTO    ADC_Read	; Volvemos a leer RA0

Update_LED6:
    movlw   196
    SUBWF   Valor_ADC,W
    BTFSC   STATUS,0
    GOTO    Update_LED7
    MOVLW   0b00111111
    MOVWF   PORTD
    GOTO    ADC_Read	; Volvemos a leer RA0

Update_LED7:
    movlw   224
    SUBWF   Valor_ADC,W
    BTFSC   STATUS,0
    GOTO    Update_LED8
    MOVLW   0b01111111
    MOVWF   PORTD
    GOTO    ADC_Read	; Volvemos a leer RA0

Update_LED8:
    movlw   250
    SUBWF   Valor_ADC,W
    BTFSC   STATUS,0
    GOTO    ADC_Read	; Volvemos a leer RA0
    MOVLW   0b11111111
    MOVWF   PORTD
    GOTO    ADC_Read	; Volvemos a leer RA0

;********** C O D I G O * R E T A R D O S **************************************
; Las siguientes lineas duran
; Retardo = 1 + M + M + KM + (K-1)M + 2M + (K-1)2M + (M-1) + 2 + 2(M-1) + 2
; Retardo = 2 + 4M + 4KM para K=249 y suponiendo M=1 tenemos
; Retardo = 1002 us = 1 ms
Retardo_ms:
	movwf	RContadorB		; 1 ciclos máquina.
Retardo_BucleExterno:
	movlw	249                     ; Mx1 ciclos máquina. Este es el valor de "K".
	movwf	RContadorA              ; Mx1 ciclos máquina.
Retardo_BucleInterno:
	nop                             ; KxMx1 ciclos máquina.
	decfsz	RContadorA,F            ; (K-1)xMx1 cm (si no salta) + Mx2 cm (al saltar).
	goto	Retardo_BucleInterno    ; (K-1)xMx2 ciclos máquina.
	decfsz	RContadorB,F            ; (M-1)x1 cm (si no salta) + 2 cm (al saltar).
	goto	Retardo_BucleExterno	; (M-1)x2 ciclos máquina.
	return                          ; 2 ciclos máquina.
 
END RESETSys     ;Fin del programa


