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
		ADRS		; ENDEREÇO A SER IMPRESSO
		;NOVAS VARIÁVEIS

	ENDC			;FIM DO BLOCO DE MEMÓRIA
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                        FLAGS INTERNOS                           *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; DEFINIÇÃO DE TODOS OS FLAGS UTILIZADOS PELO SISTEMA
	#DEFINE	FLAG_0  FLAG,0	    ; AQUI INDICA QUE É O PRIMEIRO BYTE CHEGANDO
;	#DEFINE	FLAG_1  FLAG,1	    ; INDICA SE O SEGUNDO BYTE CHEGOU
;	#DEFINE	FLAG_2  FLAG,2	    ; INDICA SE O CHECK_SUM CHEGOU
	#DEFINE	ALL_RECIEVED  FLAG,3	    ; INDICA SE O CHECK_SUM CHEGOU
	#DEFINE FLAG_7	FLAG,7	    ; INDICA SE OUVE ERRO NO CHECKSUM
	#DEFINE	ADRS_0  ADRS,0	    ; INDICA 2 BYTES FORAM ENVIADOS
	#DEFINE ADRS_1	ADRS,1
	#DEFINE ADRS_3	ADRS,3	    
	
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
	;BCF	GPIO,GP0    ; SINAL ENVIADO AO SHIFT-REGISTER, SERVIU PARA O TESTE
	BCF	STATUS,C
	GOTO	FIM
SETA
	;BSF	GPIO,GP0    ; TESTE DE RECEiVING DO MASTER              
	BSF	STATUS,C
FIM
	RLF	AUX1	    ; GUARDA O VALOR ENVIADO DO MASTER
	;BSF	GPIO,GP4
	;BCF	GPIO,GP4
	DECFSZ	COUNTER	    
	GOTO	CONTINUA
	BSF	FLAG_0	    ; FLAG_0 = 1, O SLAVE ESPERA NOVAMENTE
CONTINUA
	MOVF	AUX1,W
	MOVWF	CHECK_SUM
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

	
;UPDATE_DATA		    ; ************ SUBROTINA 2 *******************
;	BCF	STATUS,C
;	RLF	DADO
;	DECFSZ	VAR
;	GOTO	UPDATE_DATA
;	   
;	MOVF	ADRS,W	    ; GUARDA O ENDEREÇO	
;	IORWF	DADO,W	    ; 
;	MOVWF	DADO	
;	MOVLW	.4
;	MOVWF	VAR
;	BCF	STATUS,C
;	RRF	ADRS	    ; ATUALIZA O ENDEREÇO DE ENVIO	
;	RETURN

VER_ERRO
	MOVF	AUX3,W
	ADDWF	AUX1,W
	
	SUBWF	CHECK_SUM
	BTFSS	STATUS,C
	GOTO	OUVE_ERRO
	BCF	FLAG_7	    ; NÃO OUVE ERRO
OUVE_ERRO
	BSF	FLAG_7
	RETURN
	
DELAY
	BTFSS	PIR1,TMR1IF	;VERIFICA SE HOUVE ESTOURO NA FLAG
	GOTO	DELAY
	;BCF	PIR1,TMR1IF
	BCF	T1CON,0	    ; DESABILITA O TIMER1
	RETURN
	
MEU_DADO0
	BCF	STATUS,C
	RLF	DADO
	DECFSZ	VAR
	GOTO	MEU_DADO0
	   
	MOVLW	B'00001000'     ; ENDEREÇO DO DISPLAY 1	
	IORWF	DADO,W		; 
	MOVWF	DADO	
	MOVLW	.4
	MOVWF	VAR
	RETURN
	
MEU_DADO1
	BCF	STATUS,C
	RLF	DADO
	DECFSZ	VAR
	GOTO	MEU_DADO1
	   
	MOVLW	B'00000100'     ; ENDEREÇO DO DISPLAY 1	
	IORWF	DADO,W		; 
	MOVWF	DADO	
	MOVLW	.4
	MOVWF	VAR
	RETURN
	
MEU_DADO2
	BCF	STATUS,C
	RLF	DADO
	DECFSZ	VAR
	GOTO	MEU_DADO2
	   
	MOVLW	B'00000010'     ; ENDEREÇO DO DISPLAY 1	
	IORWF	DADO,W		; 
	MOVWF	DADO	
	MOVLW	.4
	MOVWF	VAR
	RETURN
	
MEU_DADO3
	BCF	STATUS,C
	RLF	DADO
	DECFSZ	VAR
	GOTO	MEU_DADO3
	   
	MOVLW	B'00000001'     ; ENDEREÇO DO DISPLAY 1	
	IORWF	DADO,W		; 
	MOVWF	DADO	
	MOVLW	.4
	MOVWF	VAR
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
	
	BANK0				;RETORNA PARA O BANCO
	MOVLW	B'00000111'	; 011 CONFIGURAÇÃO DO COMPARADOR
	MOVWF	CMCON		;DEFINE O MODO DE OPERAÇÃO DO COMPARADOR ANALÓGICO
	MOVLW	B'00100000'	;PRESCALE DE 1:4
	MOVWF	T1CON
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     INICIALIZAÇÃO DAS VARIÁVEIS                 *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	MOVLW	.8
	MOVWF	COUNTER
	MOVLW	.4
	MOVWF	VAR
	MOVLW	B'10001000'
	MOVWF	ADRS
	CLRF	GPIO
	MOVLW	B'00000000'
	MOVWF	AUX3	
	MOVWF	AUX2
	MOVWF	AUX4
	MOVWF	AUX5
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     ROTINA PRINCIPAL                            *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
MAIN
	; ------------------ PARTE DE SINCRONIZAÇÃO PRONTA (FUNCIONA) ------------------
	MOVLW	.240
	MOVWF	TMR0
TESTA
	BTFSS	GPIO,GP2
	GOTO	MAIN	    ;ENQUANTO GP2, REINICIE O TMR0
	BTFSS	INTCON,T0IF ; SE GP2=1 NUM TEMPO SUFICIENTE
	GOTO	TESTA	    ; SE GP2=0, ANTES QUE ESTOURE, É ZERADO O TMR0
	
	MOVLW	B'10010000'
	MOVWF	INTCON
	BCF	FLAG_0	    ; FLAG QUE INDICA SE TODOS OS DADOS FORAM RECEBIDOS
	
LOOP			    ; ESPERA A INTERRUPÇÃO DE RECEBIMENTO DOS DADOS
	BTFSS	FLAG_0	    ; PRECISO ENVIAR OS DADOS NO LOOP
	GOTO	GUARDEI
	GOTO	FIM_LOOP
GUARDEI

	MOVF 	AUX3,W		; ESSA PARTE FUNCIONA
	MOVWF	DADO
	CALL	MEU_DADO0
	CALL	ENVIA
	
	MOVF	AUX5,W
	MOVWF	DADO
	CALL	MEU_DADO1
	CALL	ENVIA
	
	MOVF	AUX2,W		; ESSA PARTE FUNCIONA
	MOVWF	DADO
	CALL	MEU_DADO2
	CALL	ENVIA
	
	MOVF	AUX4,W
	MOVWF	DADO
	CALL	MEU_DADO3
	CALL	ENVIA
	
	GOTO	LOOP
FIM_LOOP
	;BSF	GPIO,GP5    ; PULSO DE CLOCK QUE PERMITE
	;BCF	GPIO,GP5    ; OS DADOS SEJAM ENVIADOS PARA OS DISPLAYS
	CLRF	INTCON	    ; LIMPA TODAS AS INTERRUPÇÕES	
	MOVLW	.8	    ; RENOVA O VALOR DE COUNTER
	MOVWF	COUNTER	    ; APÓS O ENVIO DOS 8 BITS
; *************** FINAL DA PARTE DE SINCRONIZAÇÃO ********************	
	
	BTFSS	ADRS_3	    ; (BIT_3 = 1) SE O PRIMEIRO BYTE CHEGOU ENTÃO SALVO O VALOR
	GOTO	BYTE_2	    ; NA VARIÁVEL AUX3
	MOVF	AUX1,W	    ; 0000 1000
	MOVWF	AUX3	    ; GUARDA O PRIMEIRO VALOR DE AUX1 (1º BYTE)
	MOVWF	AUX5
	SWAPF	AUX5
	
BYTE_2
	BTFSS	ADRS_1	    ; BIT_1 DO ADRS = 1, ENTÃO O SEGUNDO BYTE CHEGOU
	GOTO	OPA
	MOVF	AUX1,W	    ; CASO O SEGUNDO BYTE TENHA CHEGADO
	MOVWF	AUX2	    ; GUARDO O VALOR DELE PARA UM CHECKSUM POSTERIORMENTE
	MOVWF	AUX4
	SWAPF	AUX4	    ; GUARDANDO O NIBBLE MAIS SIGNIFICATIVO(ESPERO QUE FUNCIONE)
	GOTO	DEU_CERTO
OPA
	BSF	ADRS_1
	BCF	INTCON,T0IF
	GOTO	MAIN
		
DEU_CERTO
	MOVLW	B'00001000'	; TODOS OS BYTES ENVIADOS, LIMPA O VALOR DE ADRS
	MOVWF	ADRS		; ATUALIZO VALOR INICIAL DO ENDEREÇO
	BCF	INTCON,T0IF	; LIMPA INTERRUPÇÕES
	GOTO	MAIN	

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                       FIM DO PROGRAMA                           *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	END
