;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*              MODIFICAÇÕES PARA USO COM 12F675                   *
;*                FEITAS PELO PROF. MARDSON                        *
;*                      JUNHO DE 2019                              *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                       NOME DO PROJETO                           *
;*                           CLIENTE                               *
;*         DESENVOLVIDO PELA MOSAICO ENGENHARIA E CONSULTORIA      *
;*   VERSÃO: 1.0                           DATA: 17/06/03          *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     DESCRIÇÃO DO ARQUIVO                        *
;*-----------------------------------------------------------------*
;*   MODELO PARA O PIC 12F675                                      *
;*                                                                 *
;*                                                                 *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     ARQUIVOS DE DEFINIÇÕES                      *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#INCLUDE <p12f675.inc>	;ARQUIVO PADRÃO MICROCHIP PARA 12F675

	__CONFIG _BODEN_OFF & _CP_OFF & _PWRTE_ON & _WDT_OFF & _MCLRE_ON & _INTRC_OSC_NOCLKOUT

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                    PAGINAÇÃO DE MEMÓRIA                         *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;DEFINIÇÃO DE COMANDOS DE USUÁRIO PARA ALTERAÇÃO DA PÁGINA DE MEMÓRIA
#DEFINE	BANK0	BCF STATUS,RP0	;SETA BANK 0 DE MEMÓRIA
#DEFINE	BANK1	BSF STATUS,RP0	;SETA BANK 1 DE MAMÓRIA

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                         VARIÁVEIS                               *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINIÇÃO DOS NOMES E ENDEREÇOS DE TODAS AS VARIÁVEIS UTILIZADAS 
; PELO SISTEMA

	CBLOCK	0x20	;ENDEREÇO INICIAL DA MEMÓRIA DE
					;USUÁRIO
		W_TEMP		;REGISTRADORES TEMPORÁRIOS PARA USO
		STATUS_TEMP	;JUNTO ÀS INTERRUPÇÕES
		
		COUNTER		; SABER SE CHEGOU UM BYTE
		VAR		; USADA NO ROTATE
		DADO		; VARIÁVEL QUE É ENVIADA
		FLAG		; INDICA QUE O BYTE CHEGOU
		AUX1		; 
		AUX2		; GUARDA O VALOR DO DADO_2 E DADO_3
		AUX3		; GUARDA O VALOR DO DADO_1 E DADO_0
		AUX4		; GUARDA O NIBBLE MAIS SIGNIFICATIVO DE AUX3
		AUX5		; GUARDA O NIBBLE MAIS SIGNIFICATIVO DE AUX2  
		CHECK_SUM	; VERIFICA SE OS DADOS ESTÃO CORRETOS
		VARH
		ADRS		; ENDEREÇO A SER IMPRESSO
		COUNTER2
		;NOVAS VARIÁVEIS

	ENDC			;FIM DO BLOCO DE MEMÓRIA
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                        FLAGS INTERNOS                           *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINIÇÃO DE TODOS OS FLAGS UTILIZADOS PELO SISTEMA
	#DEFINE	FLAG_0  FLAG,0		    ; AQUI INDICA QUE É O PRIMEIRO BYTE CHEGOU
	#DEFINE	SEM_ERRO  FLAG,1	    ; SINALIZA SE HOUVE ERRO
	#DEFINE	TIME_OUT  FLAG,2   
	
	
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
;*                       VETOR DE RESET                            *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	ORG	0x00			;ENDEREÇO INICIAL DE PROCESSAMENTO
	GOTO	INICIO
	
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                    INÍCIO DA INTERRUPÇÃO                        *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; ENDEREÇO DE DESVIO DAS INTERRUPÇÕES. A PRIMEIRA TAREFA É SALVAR OS
; VALORES DE "W" E "STATUS" PARA RECUPERAÇÃO FUTURA

	ORG	0x04			;ENDEREÇO INICIAL DA INTERRUPÇÃO
	MOVWF	W_TEMP		;COPIA W PARA W_TEMP
	SWAPF	STATUS,W
	MOVWF	STATUS_TEMP	;COPIA STATUS PARA STATUS_TEMP

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                    ROTINA DE INTERRUPÇÃO                        *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; AQUI SERÃO ESCRITAS AS ROTINAS DE RECONHECIMENTO E TRATAMENTO DAS
; INTERRUPÇÕES

	BTFSC	GPIO,GP1    ;O QUE É LIDO É DIRETAMENTE ENVIADO
	GOTO	SETA
	
	BCF	STATUS,C
	GOTO	FIM
SETA          
	BSF	STATUS,C
FIM
	RLF	AUX1	    ; GUARDA O VALOR ENVIADO DO MASTER
	DECFSZ	COUNTER	    
	GOTO	CONTINUA
	BSF	FLAG_0	    ; FLAG_0 = 1, O SLAVE ESPERA NOVAMENTE
CONTINUA
	;CLRF	TMR1L
	;CLRF	TMR1H
	BCF	PIR1,TMR1IF
	BCF	INTCON,INTF
	
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                 ROTINA DE SAÍDA DA INTERRUPÇÃO                  *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; OS VALORES DE "W" E "STATUS" DEVEM SER RECUPERADOS ANTES DE 
; RETORNAR DA INTERRUPÇÃO

SAI_INT
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

ENVIA			; ************ SUBROTINA 1 *******************
	RLF	DADO	    ; RECEBE TODOS OS VALORES PARA SEREM ENVIADOS
	BTFSC	STATUS,C    ; BASTA ATUALIZAR DADO 
	GOTO	SETA1
	BCF	GPIO,GP0
	GOTO	FIM_ENVIA
SETA1
	BSF	GPIO,GP0
	
FIM_ENVIA
	BSF	GPIO,GP4	; PULSO DO SLAVE PARA O SHIFT-REGISTER 
	BCF	GPIO,GP4	;
	DECFSZ	COUNTER
	GOTO	ENVIA
	
	BSF	GPIO,GP5	; PULSO GERAL DO SLAVE QUE ENVIA TODOS OS 
	BCF	GPIO,GP5	; BITS PARA OS DISPLAYS DE 7 SEG
	MOVLW	.8
	MOVWF	COUNTER
	
	RETURN

; ************************** FUNÇÃO DE VERIFICAÇÃO DE ERRO ***************************
VER_ERRO
	MOVF	AUX3,W
	ADDWF	AUX2		   ; VERIFICAR SE A SOMA PASSOU DE 255
	MOVF	AUX2,W
	
	BTFSC	STATUS,C
	GOTO	ESTOUROU	   ; SOMA PASSOU DE 255	    
				   ; SE NÃO PASSOU SHOW DE BOLA 
SUBTRAI
	SUBWF	CHECK_SUM
	BTFSS	STATUS,C
	GOTO	FIM_VER_ERRO
	
	MOVLW	.1
	SUBWF	CHECK_SUM
	BTFSC	STATUS,C
	GOTO	ENCONTREI_ERRO
	GOTO	NAO_DEU_ERRO

ESTOUROU			    ; SÓ ANALISO O NIBBLE MENOS SIGNIFICATIVO
	BCF	STATUS,C	    ; DESLOCA O NIBBLE MENOS SIGNIFICATIVO
	RLF	AUX2		    ; E FAZ UM SWAPF NO FINAL
	DECFSZ	VAR
	GOTO	ESTOUROU
	
	SWAPF	AUX2,W
	GOTO	SUBTRAI
	
NAO_DEU_ERRO
	BCF	SEM_ERRO
	GOTO	FIM_VER_ERRO
ENCONTREI_ERRO
	BSF	SEM_ERRO
	
FIM_VER_ERRO
	RETURN
	
; ******************************* DELAY PARA IMPRIMIR NOS DISPLAYS **************************
DELAY	
	MOVF	VARH,W
	MOVWF	TMR1H
	MOVF	FLAG,W
	MOVWF	TMR1L
LOOP_DELAY
	BTFSS	PIR1,TMR1IF	;VERIFICA SE HOUVE ESTOURO NA FLAG
	GOTO	LOOP_DELAY
	;BCF	T1CON,0	    ; DESABILITA O TIMER1
	CLRF	TMR1L
	BCF	PIR1,TMR1IF
	RETURN
	
; ******************************* ATUALIZA DADO_0 *******************************
MEU_DADO0
	BCF	STATUS,C
	RLF	DADO
	DECFSZ	VAR
	GOTO	MEU_DADO0
	
	MOVF	ADRS,W	
	IORWF	DADO,W		; 
	MOVWF	DADO	
	MOVLW	.4
	MOVWF	VAR
	BCF	STATUS,C
	RRF	ADRS
	RETURN
	
; ************************* IMPRIME EM TODOS OS DISPLAYS *************************
IMPRIME			;TESTEANDO
	BSF	T1CON,0
	MOVLW	.253
	MOVWF	VARH
	MOVLW	.255
	MOVWF	FLAG

	MOVF	AUX5,W		; NIBBLE MAIS SIGNIFICATIVO DO
	MOVWF	DADO		; BYTE MAIS SIGNIFICATIVO
	CALL	MEU_DADO0
	CALL	ENVIA
	CALL	DELAY
	
	MOVF 	AUX3,W		; NIBBLE MENOS SIGNIFICATIVO DO
	MOVWF	DADO		; BYTE MAIS SIGNIFICATIVO
	CALL	MEU_DADO0
	CALL	ENVIA
	CALL	DELAY
	
	MOVF	AUX4,W		; NIBBLE MAIS SIGNIFICATIVO DO
	MOVWF	DADO		; BYTE MENOS SIGNIFICATIVO
	CALL	MEU_DADO0
	CALL	ENVIA
	CALL	DELAY
	
	MOVF	AUX2,W		; NIBBLE MENOS SIGNIFICATIVO DO
	MOVWF	DADO		; BYTE MENOS SIGNIFICATIVO
	CALL	MEU_DADO0
	CALL	ENVIA
	CALL	DELAY

	CLRF	TMR1L
	;CLRF	TMR1H
	BCF	T1CON,0	
	CLRF	FLAG	
	MOVLW	.8
	MOVWF	COUNTER
	MOVLW	.3
	MOVWF	COUNTER2
	MOVLW	B'00001000'
	MOVWF	ADRS
	RETURN
	
	
; ************************* GUARDANDO OS DADOS NA EEPROM ***********************
LE_EEPROM
;LER DADO DA EEPROM, CUJO ENDEREÇO É INDICADO EM W
;DADO LIDO RETORNA EM W
	ANDLW	.127		;LIMITA ENDEREÇO MAX. 127
	BANK1				;ACESSO VIA BANK 1
	MOVWF	EEADR		;INDICA O END. DE LEITURA
	BSF	EECON1,RD	;INICIA O PROCESSO DE LEITURA
	MOVF	EEDATA,W	;COLOCA DADO LIDO EM W
	BANK0				;POSICIONA PARA BANK 0
	RETURN

GRAVA_EEPROM
;ESCREVE DADO (DADO) NA EEPROM, CUJO ENDEREÇO É INDICADO EM W
	ANDLW	.127		;LIMITA ENDEREÇO MAX. 127
	BANK1				;ACESSO VIA BANK 1
	MOVWF	EEADR
	MOVF	DADO,W
	MOVWF	EEDATA
	BSF	EECON1,WREN	;HABILITA ESCRITA
	BCF	INTCON,GIE	;DESLIGA INTERRUPÇÕES
	MOVLW	B'01010101'	;DESBLOQUEIA ESCRITA
	MOVWF	EECON2		;
	MOVLW	B'10101010'	;DESBLOQUEIA ESCRITA
	MOVWF	EECON2		;
	BSF	EECON1,WR	;INICIA A ESCRITA
AGUARDA
	BTFSC	EECON1,WR	;TERMINOU?
	GOTO	AGUARDA
	BSF	INTCON,GIE	;HABILITA INTERRUPÇÕES
	BANK0				;POSICIONA PARA BANK 0
	RETURN

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     INICIO DO PROGRAMA                          *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	
INICIO
	BANK1				;ALTERA PARA O BANCO 1
	MOVLW	B'00000110'	;CONFIGURA TODAS AS PORTAS DO GPIO (PINOS)
	MOVWF	TRISIO		;COMO SAÍDAS
	CLRF	ANSEL 		;DEFINE PORTAS COMO Digital I/O
	MOVLW	B'01000000'
	MOVWF	OPTION_REG	;DEFINE OPÇÕES DE OPERAÇÃO
	MOVLW	B'00000000'	;INTERRUPÇÃO DE PERIFÉRICO HABILITADO
	MOVWF	INTCON		;DEFINE OPÇÕES DE INTERRUPÇÕES
	;CALL	0X3FF
	;MOVWF	OSCCAL
	
	BANK0				;RETORNA PARA O BANCO
	MOVLW	B'00000111'	; 011 CONFIGURAÇÃO DO COMPARADOR
	MOVWF	CMCON		;DEFINE O MODO DE OPERAÇÃO DO COMPARADOR ANALÓGICO
	MOVLW	B'00100000'	;PRESCALE DE 1:2
	MOVWF	T1CON
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     INICIALIZAÇÃO DAS VARIÁVEIS                 *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	MOVLW	.8
	MOVWF	COUNTER		    
	MOVLW	.4
	MOVWF	VAR
	CLRF	GPIO
	MOVLW	B'00000000'
	MOVWF	AUX3	
	MOVWF	AUX2
	MOVWF	AUX4
	MOVWF	AUX5
	MOVLW	.3
	MOVWF	COUNTER2
	CLRF	TMR1L
	MOVLW	B'00001000'
	MOVWF	ADRS

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     ROTINA PRINCIPAL                            *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
MAIN
	; ------------------ PARTE DE SINCRONIZAÇÃO PRONTA (FUNCIONA) ------------------
	
	MOVLW	.240		    
	MOVWF	TMR0
TESTA
	BTFSS	GPIO,GP2	    ; GP2 EM HIGH POR 40us
	GOTO	MAIN		    ;ENQUANTO GP2, REINICIE O TMR0
	BTFSS	INTCON,T0IF	    ; SE GP2=1 NUM TEMPO SUFICIENTE
	GOTO	TESTA		    ; SE GP2=0, ANTES QUE ESTOURE, É ZERADO O TMR0
	
	MOVLW	B'10010000'	    ; HABILITO INTERRUPÇÃO POR TMR0 TAMBÉM
	MOVWF	INTCON
	BCF	FLAG_0		    ; FLAG QUE INDICA SE TODOS OS DADOS FORAM RECEBIDOS
	BSF	T1CON,0
	MOVLW	.250
	MOVWF	TMR1H
	
LOOP				    ; ESPERA A INTERRUPÇÃO DE RECEBIMENTO DOS DADOS
	BTFSC	FLAG_0		    ; PRECISO ENVIAR OS DADOS NO LOOP
	GOTO	GUARDA_BYTE
				    ;TIME-OUT DE 6ms
	BTFSC	PIR1,TMR1IF
	GOTO	DEU_CERTO	    ; CASO DÊ TIME-OUT EXIBE O QUE JÁ FOI SALVO NAS VARIÁVEIS	
	GOTO	LOOP		    ; SERÃO EXIBIDOS OS ÚLTIMOS VALORES SALVOS NA EEPROM
	
GUARDA_BYTE
	BCF	T1CON,0
	
	MOVLW	.1
	SUBWF	COUNTER2,W
	BTFSS	STATUS,C	    ; C=1 DADO >= W
	GOTO	DEU_CERTO	    ; C=0 DADO < W
	
	MOVLW	.2
	SUBWF	COUNTER2,W
	BTFSS	STATUS,C
	GOTO	TERCEIRO_B_CHEGOU
	
	MOVLW	.3
	SUBWF	COUNTER2,W
	BTFSS	STATUS,C
	GOTO	SEGUNDO_B_CHEGOU
	
	;   -------------- CHEGOU O PRIMEIRO BYTE ---------------
	MOVF	AUX1,W
	MOVWF	AUX3
	MOVWF	AUX5
	SWAPF	AUX5
	GOTO	TESTE
	
SEGUNDO_B_CHEGOU
	MOVF	AUX1,W
	MOVWF	AUX2
	MOVWF	AUX4
	SWAPF	AUX4
	GOTO	TESTE
	
TERCEIRO_B_CHEGOU
	MOVF	AUX1,W
	MOVWF	CHECK_SUM
	CLRF	INTCON
	GOTO	DEU_CERTO
TESTE
	DECFSZ	COUNTER2    
	GOTO	ESPERA_PROXIMO_BYTE
	GOTO	DEU_CERTO
	
ESPERA_PROXIMO_BYTE	
	MOVLW	.8	    ; RENOVA O VALOR DE COUNTER
	MOVWF	COUNTER	    ; APÓS O ENVIO DOS 8 BITS
	BCF	FLAG_0
	BSF	T1CON,0
	CLRF	TMR1L
	MOVLW	.250
	MOVWF	TMR1H
	BCF	PIR1,TMR1IF
	GOTO	LOOP
; *************** FINAL DA PARTE DE SINCRONIZAÇÃO ********************	
	
DEU_CERTO
	
	MOVLW	.8
	MOVWF	COUNTER
	MOVLW	.3
	MOVWF	COUNTER2
	
	MOVF	AUX2,W	    
	MOVWF	AUX1		;SALVA ESTADO ANTERIOR DE AUX2
	CALL	VER_ERRO
	MOVF	AUX1,W
	MOVWF	AUX2
	;********************** SEÇÃO DE ENVIO ( MUDAR A ORDEM DOS NIBBLES DEPOIS ) ********************
	BTFSC	SEM_ERRO    ; SEM_ERRO = 0, ENTÃO DEU TUDO CERTO
	GOTO	DEU_RUIM

	CALL	IMPRIME
	MOVLW	.4
	MOVWF	VAR
	MOVLW	.8
	MOVWF	COUNTER		    
	;MOVLW	.4
	;MOVWF	VAR
	CLRF	GPIO
	;MOVLW	B'00000000'
;	MOVWF	AUX3	
;	MOVWF	AUX2
;	MOVWF	AUX4
;	MOVWF	AUX5
	MOVLW	.3
	MOVWF	COUNTER2
	CLRF	TMR1L
	MOVLW	B'00001000'
	MOVWF	ADRS
	;CLRF	TMR1L
	GOTO	INICIO
	;GOTO	MAIN
	
DEU_RUIM
	
	MOVLW	B'00011111'	; PRINTA ZERO EM TODOS OS DISPLAYS
	MOVWF	DADO		; 
	CALL	ENVIA
	BSF	T1CON,0
	
	MOVLW	.0
	MOVWF	FLAG
	MOVLW	.60
	MOVWF	VARH
	BCF	PIR1,TMR1IF
	CALL	DELAY		; DELAY DE ALERTA POR 200ms
	
	MOVLW	B'00000000'	; DESLIGA TODO MUNDO POR 200ms
	MOVWF	DADO		
	CALL	ENVIA
	CALL	DELAY
	
	CLRF	FLAG
	MOVLW	.4
	MOVWF	VAR
	;CLRF	INTCON
	CLRF	TMR1L
	;CLRF	TMR1H
	BCF	T1CON,0
	MOVLW	B'00001000'
	MOVWF	ADRS
	GOTO	MAIN	
	;GOTO	INICIO	

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                       FIM DO PROGRAMA                           *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	END
