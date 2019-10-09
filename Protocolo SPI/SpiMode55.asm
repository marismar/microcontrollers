; Placa de aprendizagem: uStart for PIC   
; Programação em Assembly do PIC18F4550 
; Autor: Marismar Costa
    
  list p=18f4550, r=hex
  #include <p18f4550.inc>  
    CONFIG  FOSC = INTOSC_EC      ; Oscillator Selection bits (Internal oscillator, CLKO function on RA6, EC used by USB (INTCKO))
    org 0x0000 ;Inicia o programa no endereço de memória 0x00
    goto INICIO 

    org 0x0008 ;Interrupção de alta prioridade, desvia para endereço 0x08
    goto HI_INT

    org 0x0018 ;interrupção de baixa prioridade, desvia para endereço 0x18
    goto LOW_INT
  
;####### INTERRUPÇÃO DE ALTA PRIORIDADE ########
HI_INT:
;Espaço para execução em alta prioridade
;----------------------------------------
    
    btfss INTCON,TMR0IF
    goto end_int

    ;incf counter,f 

    ;movf  counter,0
    ;sublw d'127'

    ;btfss STATUS,Z
    ;goto  end_int

    movlw    b'00000010' ; RA1 
    xorwf    LATA,F
    CLRF     counter

  end_int:
    bcf	    INTCON,TMR0IF  
;----------------------------------------  
  retfie ;Volta ao curso do programa  
;################################################ 
  
;####### INTERRUPÇÃO DE BAIXA PRIORIDADE ########
LOW_INT:
;Espaço para execução em baixa prioridade
;----------------------------------------
    
    NOP
  
;----------------------------------------
  retfie ;Volta ao curso do programa  
;################################################
  
  
;##### INCIALIZAÇÃO DE VARIÁVEIS #####
  CBLOCK	0x10	;ENDEREÇO INICIAL DA MEMÓRIA DE USUÁRIO
			
		counter
		;NOVAS VARIÁVEIS
	ENDC		;FIM DO BLOCO DE MEMÓRIA

;######### ROTINA PRINCIPAL DO PROGRAMA #########
INICIO:
    CLRF	    counter 
  ;--------------------------------------

  ;LATA é usado em sáidas Digitais
  ;PORTA é usado em entradas TTL
    MOVLW   B'00000000' ;Define todas as portas de TRISA como saídas
    MOVWF   TRISA
    BCF	    LATA,2	    ;Outra forma de definir RA1 como saída
  
  ;INTCON (1,2 e 3) funcionam de acordo com os valores encontrados em RCON,IPEN
  ;Neste caso, RCON,IPEN = 0 (incialização padrão)
    bcf	    INTCON,GIE    ; Desabilita interrupções globais
    bcf	    T0CON,TMR0ON  ; Desliga Timer 0
    bsf	    INTCON,TMR0IE ; Habilita interrupção Timer 0
    bcf	    T0CON,T08BIT  ; Utiliza modo de 16 bits
    bcf	    T0CON,T0CS    
    bcf	    T0CON,T0PS2   ;0
    bcf	    T0CON,T0PS1   ;0		DEFINE PRESCALER PARA 1:4
    bcf	    T0CON,T0PS0   ;0
  
  ;Inicializa timer
    movlw   0x00
    movwf   TMR0H
    movlw   0x00
    movwf   TMR0L
 
  ;INTCON2,TMR0IP define se o estouro do timer desvia para hi_int ou low_int
    bsf	    INTCON2,TMR0IP ; Timer 0 - INTCON2,TMR0IP = 1 - Alta prioridade
    bsf	    T0CON,TMR0ON   ; Timer 0 - Habilita Timer0
    bcf	    INTCON,GIE     ; Habilita interrupções globais
     
  
    CLRF    PORTC ; Initialize PORTC by
    CLRF    LATC ; Alternate method
    MOVLW   07h ; Value used to
    movlw   B'00000000'
    MOVWF   TRISC ; RC<5:0> as outputs
    
    
    CLRF    PORTB ; Initialize PORTB by
    CLRF    LATB ; Alternate method
    MOVLW   0Eh ; Set RB<4:0> as
    MOVLW   B'00001111'
    MOVWF   ADCON1 ; digital I/O pins
    MOVLW   0CFh ; Value used to
    MOVLW   B'00000001'
    MOVWF   TRISB
    
    ;TENTANDO AJUSTAR O SPI MODE
    MOVLW   B'00110000'
    MOVWF   SSPCON1		; CONTROLE DO SPI MODE
    MOVLW   B'10000000'
    MOVWF   SSPSTAT		; LEITURA DO STATUS
    
    ;TENTATIVA DE AJUSTAR O CLOCK
    MOVLW   B'00010111'
    MOVWF   OSCCON
    MOVLW   B'10010000'
    MOVWF   OSCTUNE
    
    ;MOVLW   B'01100111'
    ;MOVWF   OSCCON
    ;MOVLW   B'10000000'
    ;MOVWF   OSCTUNE
    
loop
    ;nop   
    BSF	    LATA,2
    
;DELAY1
;    BTFSS   INTCON,TMR0IF
;    GOTO    DELAY1
    
    ;BCF	    LATA,2
    ; Serial Data Out (SDO) ? RC7/RX/DT/SDO
    ; Serial Clock (SCK) ? RB1/AN10/INT1/SCK/SCL
    ; CKE E CKP CONTROLAM O MODO DE OPERAÇÃO DO CLOCK DO MASTER
    ; CKE = 1, CKP = 1 ESCOLHIDO POR MARISMAR
    ; CKE = 0, CKP = 1 ESCOLHIDO POR MARISMAR
    ;MOVLW   B'00111000'
    ;MOVWF   SSPBUF
    ;MOVLW   B'01100100'
    ;MOVWF   SSPBUF
    

    
    ;BCF	    INTCON,TMR0IF
    
    MOVLW   B'01000111'
    MOVWF   SSPBUF
    
;DELAY2
;    BTFSS   INTCON,TMR0IF
;    GOTO    DELAY2
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    BCF	    LATA,2
    MOVLW   B'01100011'
    MOVWF   SSPBUF
    
    
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    ;BCF	    LATA,2
    MOVLW   B'10101010'
    MOVWF   SSPBUF
    
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    ;BCF	    INTCON,TMR0IF
    
    GOTO loop
end
