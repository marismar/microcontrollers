;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*               PLACA DE APRENDIZAGEM: USTART FOR PIC		   *
;*		 PROGRAMAÇÃO EM ASSEMBLY DO PIC18F4550		   *
;*			AUTOR: MARISMAR COSTA                      *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
  
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     ARQUIVOS DE DEFINIÇÕES                      *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *	
  LIST p=18f4550, r=hex
#INCLUDE <p18f4550.inc>		;ARQUIVO PADRÃO MICROCHIP PARA 18F4550
    
; CONFIG1H
  CONFIG    LVP = OFF
  CONFIG  FOSC = INTOSCIO_EC    ; OSCILLATOR SELECTION BITS (INTERNAL OSCILLATOR, PORT FUNCTION ON RA6, EC USED BY USB (INTIO))	
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                         VARIÁVEIS                               *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINIÇÃO DOS NOMES E ENDEREÇOS DE TODAS AS VARIÁVEIS UTILIZADAS 
; PELO SISTEMA

	CBLOCK	0x10		;ENDEREÇO INICIAL DA MEMÓRIA DE USUÁRIO
		W_TEMP		;REGISTRADORES TEMPORÁRIOS PARA USO
		STATUS_TEMP	;JUNTO ÀS INTERRUPÇÕES
		MAIOR_VALOR	;PARA GUARDAR O MAIOR VALOR CONVERTIDO
		
		;NOVAS VARIÁVEIS
		
		
	ENDC			;FIM DO BLOCO DE MEMÓRIA
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                        FLAGS INTERNOS                           *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINIÇÃO DE TODOS OS FLAGS UTILIZADOS PELO SISTEMA

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                         CONSTANTES                              *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINIÇÃO DE TODAS AS CONSTANTES UTILIZADAS PELO SISTEMA

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                           ENTRADAS                              *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINIÇÃO DE TODOS OS PINOS QUE SERÃO UTILIZADOS COMO ENTRADA
; RECOMENDAMOS TAMBÉM COMENTAR O SIGNIFICADO DE SEUS ESTADOS (0 E 1)

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                           SAÍDAS                                *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINIÇÃO DE TODOS OS PINOS QUE SERÃO UTILIZADOS COMO SAÍDA
; RECOMENDAMOS TAMBÉM COMENTAR O SIGNIFICADO DE SEUS ESTADOS (0 E 1)	
	
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*			      VETORES                              *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	ORG 0x0000		;ENDEREÇO INICIAL DO PROGRAMA
	GOTO INICIO
    
	ORG 0x0008		;ENDEREÇO DA INTERRUPÇÃO DE ALTA PRIORIDADE
	GOTO HIGH_INT
    
	ORG 0x0018		;ENDEREÇO DA INTERRUPÇÃO DE BAIXA PRIORIDADE
	GOTO LOW_INT
    
    
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*            INÍCIO DA INTERRUPÇÃO DE ALTA PRIORIDADE             *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; ENDEREÇO DE DESVIO DAS INTERRUPÇÕES. A PRIMEIRA TAREFA É SALVAR OS
; VALORES DE "W" E "STATUS" PARA RECUPERAÇÃO FUTURA
    
HIGH_INT:
	MOVWF	W_TEMP		;COPIA W PARA W_TEMP
	SWAPF	STATUS,W
	MOVWF	STATUS_TEMP	;COPIA STATUS PARA STATUS_TEMP

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*            ROTINA DE INTERRUPÇÃO DE ALTA PRIORIDADE             *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; AQUI SERÃO ESCRITAS AS ROTINAS DE RECONHECIMENTO E TRATAMENTO DAS
; INTERRUPÇÕES

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*       ROTINA DE SAÍDA DA INTERRUPÇÃO DE ALTA PRIORIDADE         *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; OS VALORES DE "W" E "STATUS" DEVEM SER RECUPERADOS ANTES DE 
; RETORNAR DA INTERRUPÇÃO

END_INT:
	SWAPF	STATUS_TEMP,W
	MOVWF	STATUS		;MOVE STATUS_TEMP PARA STATUS
	SWAPF	W_TEMP,F
	SWAPF	W_TEMP,W	;MOVE W_TEMP PARA W
	RETFIE
    
	
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*            INÍCIO DA INTERRUPÇÃO DE BAIXA PRIORIDADE            *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; ENDEREÇO DE DESVIO DAS INTERRUPÇÕES. A PRIMEIRA TAREFA É SALVAR OS
; VALORES DE "W" E "STATUS" PARA RECUPERAÇÃO FUTURA
	
LOW_INT:
	MOVWF	W_TEMP		;COPIA W PARA W_TEMP
	SWAPF	STATUS,W
	MOVWF	STATUS_TEMP	;COPIA STATUS PARA STATUS_TEMP

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*           ROTINA DE INTERRUPÇÃO DE BAIXA PRIORIDADE             *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; AQUI SERÃO ESCRITAS AS ROTINAS DE RECONHECIMENTO E TRATAMENTO DAS
; INTERRUPÇÕES
	
	NOP
	
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*      ROTINA DE SAÍDA DA INTERRUPÇÃO DE BAIXA PRIORIDADE         *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; OS VALORES DE "W" E "STATUS" DEVEM SER RECUPERADOS ANTES DE 
; RETORNAR DA INTERRUPÇÃO
	
	SWAPF	STATUS_TEMP,W
	MOVWF	STATUS		;MOVE STATUS_TEMP PARA STATUS
	SWAPF	W_TEMP,F
	SWAPF	W_TEMP,W	;MOVE W_TEMP PARA W
	RETFIE
    
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*	            	 ROTINAS E SUBROTINAS                      *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; CADA ROTINA OU SUBROTINA DEVE POSSUIR A DESCRIÇÃO DE FUNCIONAMENTO
; E UM NOME COERENTE ÀS SUAS FUNÇÕES.

SUBROTINA1

	;CORPO DA ROTINA

	RETURN

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     INICIO DO PROGRAMA                          *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	
INICIO:
    
	CLRF PORTA ; Initialize PORTA by
	CLRF LATA ; Alternate method
	MOVLW B'00001110' ; Configure A/D
	MOVWF ADCON1 ; for digital inputs
	MOVLW B'00000000' ; Configure comparators
	MOVWF CMCON ; for digital input
	MOVLW B'00000001' ; Value used to
	MOVWF TRISA ; Set RA<3:0> as inputs
    	MOVLW	B'00000110'
	MOVWF	ADCON2
	MOVLW	B'00000001'
	MOVWF	ADCON0
    

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     INICIALIZAÇÃO DAS VARIÁVEIS                 *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     ROTINA PRINCIPAL                            *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
MAIN

	;CORPO DA ROTINA PRINCIPAL
	BSF	ADCON0,1	;INICIA CONVERSAO
FIM_CONVERSAO
	BTFSC	ADCON0,1	;VERIFICA SE A CONVERSAO TERMINOU
	GOTO	FIM_CONVERSAO

	;BTG	LATA,1
	MOVF	ADRESH,0	;MOVE O VALOR DA CONVERSAO PARA WREG
	CPFSLT	MAIOR_VALOR	;TESTA SE O NOVO VALOR CONVERTIDO É MAIOR QUE O MAIOR ANTERIORMENTE SALVO E DESVIA 
	GOTO	NOVO_MENOR	;SE NÃO, RETORNA AO MAIN
	MOVWF	MAIOR_VALOR	;ATUALIZA O MAIOR VALOR
    	BSF	LATA,2		;ACENDE LED
	GOTO	MAIN
	
NOVO_MENOR
	MOVF	ADRESH,0
	CPFSEQ	MAIOR_VALOR
	BCF	LATA,2		;APAGA LED
	GOTO	MAIN

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                       FIM DO PROGRAMA                           *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	END
