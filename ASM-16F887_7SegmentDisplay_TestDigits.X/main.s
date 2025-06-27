;*******************************************************************************
;*
;*   Control de display de 7 segmentos: Ejemplo basico de 1 digito
;*
;*******************************************************************************
;* FileName:        main.asm
;* Processor:       PIC16F887
;* Complier:        PIC-AS v2.36
;* Author:          Pedro Sánchez (MrChunckuee)
;* Blog:            http://mrchunckuee.blogspot.com/
;* Email:           mrchunckuee.psr@gmail.com
;* Description:     Pruebas basicas de algunos digitos del display de 7 segmentos 
;*		    de catodo comun, con retardos por software.
;*******************************************************************************
;* Rev.         Date            Comment
;*  v0.0.1	26/06/2025      - Creación del firmware
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
ContadorA:  DS	    1	    ;reserve 1 byte
ContadorB:  DS      1
ContadorC:  DS      1
      
; Definición de pines para transistores
#define TRANSISTOR1 PORTC, 0   ; Display 1
#define TRANSISTOR2 PORTC, 1   ; Display 2
#define TRANSISTOR3 PORTC, 2   ; Display 3
#define TRANSISTOR4 PORTC, 3   ; Display 4
    
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
    BANKSEL OSCCON
    MOVLW   0b01110001
    MOVWF   BANKMASK(OSCCON)	;Oscilador interno 8MHz --> IRCF<2:0> = 1, CCS = 1
    
    BANKSEL ANSEL
    CLRF    BANKMASK(ANSEL)	;select digital IO
    CLRF    BANKMASK(ANSELH)
    
    BANKSEL TRISC
    CLRF    BANKMASK(TRISC)	;all PORTC outputs
    BANKSEL PORTC 
    CLRF    BANKMASK(PORTC)	;Clear PORTC
    BSF     TRANSISTOR1		;Set transistor = 1
				;Esto no es necesario si usas solo el display
    
    BANKSEL TRISD
    CLRF    BANKMASK(TRISD)	;all PORTD outputs
    BANKSEL PORTD 
    CLRF    BANKMASK(PORTD)	;Clear PORTD

;********** C O D I G O * P R I N C I P A L ************************************
LOOP: 
    MOVLW   7		    ; Cargar "7"
    CALL    TABLASegmentos
    MOVWF   PORTD
    CALL    Retardo_500ms
    
    MOVLW   8		    ; Cargar "8"
    CALL    TABLASegmentos
    MOVWF   PORTD
    CALL    Retardo_500ms
    
    MOVLW   3		    ; Cargar "3"
    CALL    TABLASegmentos
    MOVWF   PORTD
    CALL    Retardo_500ms
    
    MOVLW   5		    ; Cargar "5"
    CALL    TABLASegmentos
    MOVWF   PORTD
    CALL    Retardo_500ms
    
    GOTO    LOOP

;********** T A B L A * D E * S E G M E N T O S ********************************
TABLASegmentos:
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
; Time = 2 + 1 + 1 + N + N + MN + MN + KMN + (K-1)MN + 2MN + 2(K-1)MN + (M-1)N
;        + 2N + (M-1)2N + (N-1) + 2 + 2(N-1) + 2
; Time = (5 + 4N + 4MN + 4KM) ciclos máquina. Para K=249, M=100 y N=10
; Time = 5 + 40 + 4000 + 996000 ciclos maquina
; Time = 1000045 * 0.5uS = 0.5 segundos
Retardo_500ms:				; 2 ciclo máquina
	movlw	10                      ; 1 ciclo máquina. Este es el valor de "N"
	movwf	ContadorC               ; 1 ciclo máquina.
Retardo_BucleExterno2:
	movlw	100                     ; Nx1 ciclos máquina. Este es el valor de "M".
	movwf	ContadorB               ; Nx1 ciclos máquina.
Retardo_BucleExterno:
	movlw	249                     ; MxNx1 ciclos máquina. Este es el valor de "K".
	movwf	ContadorA               ; MxNx1 ciclos máquina.
Retardo_BucleInterno:
	nop                             ; KxMxNx1 ciclos máquina.
	decfsz	ContadorA,F             ; (K-1)xMxNx1 cm (si no salta) + MxNx2 cm (al saltar).
	goto	Retardo_BucleInterno    ; (K-1)xMxNx2 ciclos máquina.
	decfsz	ContadorB,F             ; (M-1)xNx1 cm (si no salta) + Nx2 cm (al saltar).
	goto	Retardo_BucleExterno	; (M-1)xNx2 ciclos máquina.
	decfsz	ContadorC,F             ; (N-1)x1 cm (si no salta) + 2 cm (al saltar).
	goto	Retardo_BucleExterno2	; (N-1)x2 ciclos máquina.
	return                          ; 2 ciclos máquina.
    
END RESETSys