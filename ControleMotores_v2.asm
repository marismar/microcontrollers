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
  CONFIG  FOSC = INTOSCIO_EC    ; OSCILLATOR SELECTION BITS (INTERNAL OSCILLATOR, PORT FUNCTION ON RA6, EC USED BY USB (INTIO))
	
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                         VARIÁVEIS                               *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINIÇÃO DOS NOMES E ENDEREÇOS DE TODAS AS VARIÁVEIS UTILIZADAS 
; PELO SISTEMA

	CBLOCK	0x10		;ENDEREÇO INICIAL DA MEMÓRIA DE USUÁRIO
		W_TEMP		;REGISTRADORES TEMPORÁRIOS PARA USO
		STATUS_TEMP	;JUNTO ÀS INTERRUPÇÕES
		
		;VARIÁVEIS GERAIS
		THETA		;ANGULO DO PRIMEIRO SERVO MOTOR	
		PHI		;ANGULO DO SEGUNDO SERVO MOTOR	
		ANGULO_ATIVO	;ÂNGULO QUE ESTÁ SENDO AJUSTADO, 0 - TETA / 1 - PHI
		
		;VARIÁVEIS AUXILIARES PARA GERAÇÃO DE DELAY
		CONTADOR_DELAY	;AUXILIAR NA REPETIÇÃO DO DELAY DE 10 MICROSEGUNDOS
		FIM_PERIODO	;SINALIZA QUANDO O PERIODO DE 20 MILISEGUNDOS 
		DELAY1		
		DELAY2
		DELAY3

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
	
	BCF	INTCON,TMR0IF	;INTERRUPÇÃO POR TIMER0, LIMPA A FLAG
	MOVLW	.1		
	MOVWF	FIM_PERIODO	;SETA O SINALIZADOR DO FIM DO PERIODO DE 20 MILISEGUNDOS
	
	MOVLW	.1		;TESTAR SE O ANGULO_ATIVO É PHI OU THETA
	ANDWF	ANGULO_ATIVO,0	;ANGULO_ATIVO = 0 - THETA / 1 - PHI
	BTFSS	STATUS,Z	
	GOTO	ANGULO_PHI
	
	INCF	THETA		;INCREMENTA O ÂNGULO THETA
	MOVF	THETA,0		;COPIA O VALOR DE THETA PARA WORK
	SUBLW	.181		
	BTFSS	STATUS,Z	;TESTA SE THETA FOI INCREMENTADO A 181 GRAUS
	GOTO	END_INT		;SE THETA < 181, ENTÃO DESVIA PARA O FIM DA INTERRUPÇÃO 
	CLRF	THETA		;SE THETA FOR 181, ENTAO THETA RETORNA A 0 GRAUS
	MOVLW	.1
	MOVWF	ANGULO_ATIVO	;ALTERA O ANGULO_ATIVO PARA PHI
	
ANGULO_PHI
	INCF	PHI		;INCREMENTA O ÂNGULO PHI
	MOVF	PHI,0		;COPIA O VALOR DE PHI PARA WORK
	SUBLW	.181		
	BTFSS	STATUS,Z	;TESTA SE PHI FOI INCREMENTADO A 181 GRAUS
	GOTO	END_INT		;SE PHI < 181, ENTÃO DESVIA PARA O FIM DA INTERRUPÇÃO 
	CLRF	PHI		;SE PHI FOR 181, ENTAO PHI RETORNA A 0 GRAUS
	CLRF	ANGULO_ATIVO	;ALTERA O ANGULO_ATIVO PARA THETA
	
	
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

DELAY_600U
	;CORPO DA ROTINA1
	CLRF	DELAY1
	MOVLW	.10		;VALOR INICIAL DO DELAY2
	MOVWF	DELAY2
LOOP1
	DECFSZ	DELAY1		
	GOTO	LOOP1
	DECFSZ	DELAY2
	GOTO	LOOP1
	RETURN
	
	
DELAY_AUXILIAR
	;CORPO DA ROTINA2
	CLRF	WREG		;LIMPA O REGISTRADOR WORK
	SUBWF	CONTADOR_DELAY,0;SE CONTADOR FOR 0, DESVIA PARA O RETORNO DA SUBROTINA
	BTFSC	STATUS,Z	;TESTA O BIT ZERO DO STATUS
	RETURN			;NÃO EXECUTA O DELAY, POIS O ANGULO É 0 
DELAY_10U
	MOVLW	.40		;VALOR INICIAL DO DELAY2
	MOVWF	DELAY3		
LOOP2				;CADA CICLO EQUIVALE A 10USEGUNDOS    
	DECFSZ	DELAY3
	GOTO	LOOP2
	DECFSZ	CONTADOR_DELAY	;REPETE O CICLO VÁRIAS VEZES DE ACORDO COM O ÂNGULO
	GOTO	DELAY_10U
	RETURN

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     INICIO DO PROGRAMA                          *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	
INICIO:
    
	CLRF	TRISA		;DEFINE TODAS AS PORTAS RA<7:0> COMO SAÍDAS
	CLRF	LATA		;LIMPA AS SAÍDAS RA<7:0>
	MOVLW	B'10000001'	;CONFIGURAÇÃO DO TIMER0
	MOVWF	T0CON
	MOVLW	B'11100000'	;CONFIGURAÇÃO DA INTERRUPÇÃO PELO TIMER0
	MOVWF	INTCON
	MOVLW	B'00000100'	;A INTERRUOÇÃO DO TIMER0 É DEFINIDA COMO ALTA
	MOVWF	INTCON2

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     INICIALIZAÇÃO DAS VARIÁVEIS                 *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
			
	CLRF	THETA		;ÂNGULO INICIAL: 0 GRAUS
	CLRF	PHI		;ÂNGULO INICIAL: 0 GRAUS
	CLRF	ANGULO_ATIVO	;INICIALIZA O PROGRAMA AJUSTANDO O THETA
	
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     ROTINA PRINCIPAL                            *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
MAIN
	;CORPO DA ROTINA PRINCIPAL
	MOVLW	.1
	ANDWF	ANGULO_ATIVO	    ;VERIFICA QUAL O ANGULO DEVE SER AJUSTADO	
    	BTFSS	STATUS,Z	    
	GOTO	ALTERA_PHI	    ;SE Z = 0, ANGULO_ATIVO = PHI
	BSF	LATA,1		    ;SE Z = 1, ANGULO_ATIVO = THETA
	CLRF	FIM_PERIODO	    ;LIMPA O SINALIZADOR DO TÉRMINO DO PERÍODO
	CALL	DELAY_600U	    ;PERMANECE POR 600USEGUNDOS
	MOVFF	THETA,CONTADOR_DELAY;MAIS THETA*10USEGUNDOS EM NÍVEL ALTO
	CALL	DELAY_AUXILIAR	    ;CONTADOR É INICIALIZADO COM O VALOR DO ÂNGULO
	BCF	LATA,1		    ;ATÉ O PERÍODO TERMINAR, RA1 = 0	
	GOTO	TERMINOU_PERIODO    ;ESPERA O PERÍODO DE 20 MILISEGUNDOS ACABAR
	
ALTERA_PHI
	BSF	LATA,2		    ;RA2 EQUIVALE AO SINAL DO SERVO MOTOR 2, PHI
	CLRF	FIM_PERIODO	    ;LIMPA O SINALIZADOR DO TÉRMINO DO PERÍODO
	CALL	DELAY_600U	    ;PERMANECE POR 600USEGUNDOS
	MOVFF	PHI,CONTADOR_DELAY  ;MAIS PHI*10USEGUNDOS EM NÍVEL ALTO
	CALL	DELAY_AUXILIAR	    ;CONTADOR É INICIALIZADO COM O VALOR DO ÂNGULO
	BCF	LATA,2		    ;ATÉ O PERÍODO TERMINAR, RA2 = 0	
	
TERMINOU_PERIODO
	MOVLW	.1
	ANDWF	FIM_PERIODO,0	    ;FIMPERIODO = 0 - NÃO ACABOU / 1 - ACABOU
	BTFSC	STATUS,Z	    ;SE AND = 1 -> Z = 0 -> PERIODO TERMINOU
	GOTO	TERMINOU_PERIODO    ;AGUARDA ATÉ O FIM DO PERÍODO DE 20MSEGUNDOS
	GOTO	MAIN		    ;ACABOU, RETORNA AO MAIN


;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                       FIM DO PROGRAMA                           *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	END



