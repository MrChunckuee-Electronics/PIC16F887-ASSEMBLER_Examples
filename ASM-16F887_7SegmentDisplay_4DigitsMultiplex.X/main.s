;*******************************************************************************
;*
;*   Control de display de 7 segmentos: Multiplexar 4 digitos
;*
;*******************************************************************************
;* FileName:        main.asm
;* Processor:       PIC16F887
;* Complier:        PIC-AS v2.36
;* Author:          Pedro Sánchez (MrChunckuee)
;* Blog:            http://mrchunckuee.blogspot.com/
;* Email:           mrchunckuee.psr@gmail.com
;* Description:     Miltiplxacion de 4 displays de 7 segmentos
;*******************************************************************************
;* Rev.         Date            Comment
;*  v0.0.1	01/07/2025      - Creación del firmware
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

#include <xc.inc>

;********** V A R I A B L E S **************************************************
; Objects in bank 0 memory
PSECT udata_bank0
RContadorA:	    DS	    1	    ; Reserve 1 byte
RContadorB:	    DS      1
Unidad:		    DS      1
Decena:		    DS      1
Centena:	    DS      1
Millar:		    DS      1
Contador:	    DS      1
      
; Definición de pines para transistores
#define TRANSISTOR_UNIDAD   PORTC, 0   ; Display 1
#define TRANSISTOR_DECENA   PORTC, 1   ; Display 2
#define TRANSISTOR_CENTENA  PORTC, 2   ; Display 3
#define TRANSISTOR_MILLAR   PORTC, 3   ; Display 4
    
#define Z	2  ; Definimos bit Z del registro STATUS
    
;********** I N I C I O * D E * P R O G R A M A ********************************
PSECT resetVec,class=CODE,delta=2,abs
ORG 0x0000
RESETSys:
    PAGESEL    MCUInit                ; Jump to the main routine
    GOTO       MCUInit

;********** C O F I G U R A * M C U ********************************************
PSECT mainVec,class=CODE,delta=2,abs
ORG 0x0006
MCUInit:
    BANKSEL OSCCON
    MOVLW   0b01110001
    MOVWF   BANKMASK(OSCCON)	; Oscilador interno 8MHz --> IRCF<2:0> = 1, CCS = 1
    
    BANKSEL ANSEL
    CLRF    BANKMASK(ANSEL)	; Select digital IO
    CLRF    BANKMASK(ANSELH)
    
    BANKSEL TRISC
    CLRF    BANKMASK(TRISC)	; All PORTC outputs
    BANKSEL PORTC 
    CLRF    BANKMASK(PORTC)	; Clear PORTC	
    
    BANKSEL TRISD
    CLRF    BANKMASK(TRISD)	; All PORTD outputs
    BANKSEL PORTD 
    CLRF    BANKMASK(PORTD)	; Clear PORTD
    
    BANKSEL Unidad		; Limpiamos variables
    CLRF    BANKMASK(Unidad)	; Unidad, Decena, Centena y Millar
    BANKSEL Decena 
    CLRF    BANKMASK(Decena)
    BANKSEL Centena 
    CLRF    BANKMASK(Centena)
    BANKSEL Millar
    CLRF    BANKMASK(Millar)

;********** C O D I G O * P R I N C I P A L ************************************
LOOP: 
    INCF    Unidad,1        ; Incremeto Unidad
    MOVLW   10		    
    SUBWF   Unidad,0        
    BTFSS   STATUS,Z        
    GOTO    UPDATEDisplay   ; Unidad < 10, actualizo display
    CLRF    Unidad          ; Unidad >= 10, Unidad = 0 
    INCF    Decena,1        ; Incremento Decena
    MOVLW   10		    
    SUBWF   Decena,0        
    BTFSS   STATUS,Z        
    GOTO    UPDATEDisplay   ; Decena < 10, actualizo display
    CLRF    Decena          ; Decena >= 10, Decena = 0 
    INCF    Centena,1       ; Incremento Centena
    MOVLW   10		    
    SUBWF   Centena,0
    BTFSS   STATUS,Z
    GOTO    UPDATEDisplay   ; Centena < 10, actualizo display
    CLRF    Centena         ; Centena >= 10, Centena = 0 
    INCF    Millar,1        ; Incremento Millar
    MOVLW   10		    
    SUBWF   Millar,0
    BTFSS   STATUS,Z
    GOTO    UPDATEDisplay   ; Millar < 10, actualizo display
    CLRF    Millar          ; Millar >= 10, Millar = 0 

;********** M U L T I P L E X I O N  DE  D I S P L A Y *************************  
UPDATEDisplay:
    MOVLW   5		    ; Repeticiones de visualizacion del mismo valor
    MOVWF   Contador	    ; Aprox 20ms x Contador = 100ms
                                
SHOWDisplay:
    MOVF    Unidad,0		; Obtengo digitos de 7 segmentos para Unidad
    CALL    TABLA7Segmentos	 
    BCF     TRANSISTOR_MILLAR   ; Apago display de Millar
    MOVWF   PORTD		; Cargo Unidad en PORTD
    BSF     TRANSISTOR_UNIDAD   ; Enciendo display de Unidad
    CALL    Retardo_5ms      
    MOVF    Decena,0		; Obtengo digitos de 7 segmentos para Decena
    CALL    TABLA7Segmentos
    BCF     TRANSISTOR_UNIDAD   ; Apago display de Unidad
    MOVWF   PORTD		; Cargo Decena en PORTD  
    BSF     TRANSISTOR_DECENA   ; Enciendo display de Decena
    CALL    Retardo_5ms
    MOVF    Centena,0		; Obtengo digitos de 7 segmentos para Centena
    CALL    TABLA7Segmentos	
    BCF     TRANSISTOR_DECENA   ; Apago display de Decena
    MOVWF   PORTD		; Cargo Centena en PORTB 
    BSF     TRANSISTOR_CENTENA  ; Enciendo display Centena
    CALL    Retardo_5ms
    MOVF    Millar,0		; Obtengo digitos de 7 segmentos para Millar
    CALL    TABLA7Segmentos	
    BCF     TRANSISTOR_CENTENA  ; Apago display de Centena
    MOVWF   PORTD		; Cargo Millar en PORTB 
    BSF     TRANSISTOR_MILLAR   ; Enciendo display Millar
    CALL    Retardo_5ms
    DECFSZ  Contador,1		; Contador = 0?
    GOTO    SHOWDisplay		; No, repito
    GOTO    LOOP		; Si, actualizo cuenta

;********** T A B L A * D E * S E G M E N T O S ********************************
TABLA7Segmentos:
    ADDWF   PCL, F
    ;punto,h,g,f,e,d,c,b,a
    RETLW   0b00111111     ; 0
    RETLW   0b00000110     ; 1
    RETLW   0b01011011     ; 2
    RETLW   0b01001111     ; 3
    RETLW   0b01100110     ; 4
    RETLW   0b01101101     ; 5
    RETLW   0b01111101     ; 6
    RETLW   0b00000111     ; 7
    RETLW   0b01111111     ; 8
    RETLW   0b01101111     ; 9

;********** C O D I G O * R E T A R D O S **************************************
; Considerando Fosc=8MHz, ciclo maquina (cm) = 0.5uS
; Tenemos para Retardo_5ms = 2 + 1 + 2 + (2 + 4M + 4KM) donde K=249 y M=10
; Retardo = 10002 * 0.5us = 5 ms

Retardo_5ms:		    ; 2 ciclo máquina
	MOVLW	10	    ; 1 ciclo máquina. Este es el valor de "M"
	GOTO    Retardo_ms  ; 2 ciclo máquina.

; Las siguientes lineas duran
; Retardo = 1 + M + M + KM + (K-1)M + 2M + (K-1)2M + (M-1) + 2 + 2(M-1) + 2
; Retardo = 2 + 4M + 4KM para K=249 y suponiendo M=1 tenemos
; Retardo = 1002 *0.5us = 0.5 ms
Retardo_ms:
	MOVWF	RContadorB		; 1 ciclos máquina.
Retardo_BucleExterno:
	MOVLW	249			; Mx1 ciclos máquina. Este es el valor de "K".
	MOVWF	RContadorA		; Mx1 ciclos máquina.
Retardo_BucleInterno:
	NOP				; KxMx1 ciclos máquina.
	DECFSZ	RContadorA,1		; (K-1)xMx1 cm (si no salta) + Mx2 cm (al saltar).
	GOTO	Retardo_BucleInterno	; (K-1)xMx2 ciclos máquina.
	DECFSZ	RContadorB,1		; (M-1)x1 cm (si no salta) + 2 cm (al saltar).
	GOTO	Retardo_BucleExterno	; (M-1)x2 ciclos máquina.
	RETURN				; 2 ciclos máquina.
    
END RESETSys