#INCLUDE <p12f675.inc>	
	__CONFIG _BODEN_OFF & _CP_OFF & _PWRTE_ON & _WDT_OFF & _MCLRE_ON & _INTRC_OSC_NOCLKOUT

;DEFINIÇÃO DE COMANDOS DE USUÁRIO PARA ALTERAÇÃO DA PÁGINA DE MEMÓRIA
#DEFINE	BANK0	BCF STATUS,RP0	;SETA BANK 0 DE MEMÓRIA
#DEFINE	BANK1	BSF STATUS,RP0	;SETA BANK 1 DE MAMÓRIA

	CBLOCK	0x20	;ENDEREÇO INICIAL DA MEMÓRIA DE
					;USUÁRIO
		W_TEMP		;REGISTRADORES TEMPORÁRIOS PARA USO
		STATUS_TEMP	;JUNTO ÀS INTERRUPÇÕES
		REMAINING
		BYTE		; byte a ser enviado para o display usado na rotina SEND_BYTE
		BYTE1		; primeiro byte a ser enviado para o display
   		BYTE2		; segundo byte a ser enviado
		CHECKSUM	; terceiro byte a ser enviado como a soma dos dois anteriores
		DCOUNTER	; variavel auxiliar para os delays
		DCOUNTER2
		COUNTER		; variavel auxiliar 
		

	ENDC			;FIM DO BLOCO DE MEMÓRIA

	ORG	0x00			;ENDEREÇO INICIAL DE PROCESSAMENTO
	GOTO	INICIO
	
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                    INÍCIO DA INTERRUPÇÃO                        *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	ORG	0x04			;ENDEREÇO INICIAL DA INTERRUPÇÃO
	MOVWF	W_TEMP		;COPIA W PARA W_TEMP
	SWAPF	STATUS,W
	MOVWF	STATUS_TEMP	;COPIA STATUS PARA STATUS_TEMP


SAI_INT
	SWAPF	STATUS_TEMP,W
	MOVWF	STATUS		;MOVE STATUS_TEMP PARA STATUS
	SWAPF	W_TEMP,F
	SWAPF	W_TEMP,W	;MOVE W_TEMP PARA W
	RETFIE

;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*	            	 ROTINAS E SUBROTINAS                      *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

READ_TEMPERATURE ; LE A TEMPERATURA PELO CONVERSOR A/D 

	BSF	ADCON0,GO ; começa conversao a/d
	
WAIT_CONVERSION
	BTFSC	ADCON0,GO
	GOTO	WAIT_CONVERSION

	RETURN
	
	
	
CALCULATE_BYTES ; calcula os bytes que serão transmitidos ao display
	; o conversor a/d está com uma referencia Vref = 0.4V
	; assim ele vai ler até uma temperatura de 40 graus
	;  (temperaturas maiores serão lidas como a temperatura maxima)
	; e o resultado da conversão está configurado para ser justificado a direita
	; com isso o resultado da conversão em ADRESH já é o digito mais significativo da conversão (primeiro display)
	
	MOVFW	ADRESH
	MOVWF	BYTE1
	SWAPF	BYTE1,F
	
	; o valor em ADRESL representa o valor restante, onde 0 represent 0 graus e 256 representaria 10 graus
	; então cada 25,6 unidades em ADRESL representa 1 unidade de temperatura (segundo display)
	BANK1
	MOVFW	ADRESL
	BANK0
	MOVWF	REMAINING
	
	; fazemos sucessivas subtracoes por 26 (aproximacao) ate que o resultado seja menor que 26
	; o numero de subtracoes feita, e a quantidade de unidades de temperatura (valor no segundo display)
DIV_D2
	MOVLW	.26
	SUBWF	REMAINING,W
	BTFSS	STATUS,C
	GOTO	CALC_DISPLAY3 ; remaining < 26
	
	; remaining > 26
	MOVWF	REMAINING ; remaining -= 26
	INCF	BYTE1	    ; incrementa uma unidade no segundo display
	GOTO	DIV_D2
	

CALC_DISPLAY3
	; aqui temos um valor entre 0 e 25 restante
	; podemos multiplicar esse valor por 2, para melhorar a precisão dos proximos calculos
	BCF	STATUS,C
	RLF	REMAINING ; multiplica por 2
	; agora temos um valor restante entre 0 e 50, onde cada 5 unidades representa 1 unidade no display 3
	
DIV_D3
	MOVLW	.5
	SUBWF	REMAINING,W
	BTFSS	STATUS,C
	GOTO	CALC_DISPLAY4 ; remaining < 5
	
	; remaining > 5
	MOVWF	REMAINING ; remaining -= 5
	INCF	BYTE2	    ; incrementa uma unidade no terceiro display
	GOTO	DIV_D3
	
	
CALC_DISPLAY4
	; agora temos um valor entre 0 e 4
	; so da pra distinguir em 5 possiveis valores
	; entao setamos o ultimo display para 2*remaining + C
	RLF	REMAINING ; multiplica por 2
	MOVFW	REMAINING
	
	; transfere para o byte 2
	SWAPF	BYTE2
	ADDWF	BYTE2,F
	
	
	; calcula checksum
	MOVFW	BYTE1
	ADDWF	BYTE2,W	
	MOVWF	CHECKSUM
	
	
	RETURN
	
	
	
LDELAY	;pequeno delay 11 us para controlar a frequencia de clock do master
	
	MOVLW	.2
	MOVWF	DCOUNTER
LDELAY_LOOP
	DECFSZ	DCOUNTER
	GOTO	LDELAY_LOOP
	
	RETURN
	
	
	
HDELAY	; delay de aproximadamente 100ms para ser usado entre as medidas
	MOVLW	.5
	MOVWF	DCOUNTER
	
HDELAY_LOOP
	DECFSZ	DCOUNTER
	GOTO	HDELAY_LOOP2
	
	RETURN
	
HDELAY_INNER_DELAY
	MOVLW	.255
	MOVWF	DCOUNTER2
	
HDELAY_LOOP2
	DECFSZ	DCOUNTER2
	GOTO	HDELAY_LOOP2
	
	GOTO	HDELAY_LOOP
	
	
	
	
SEND_CARRY  ;envia o conteudo do carry para a porta de dados do display
	
	BTFSS	STATUS,C
	GOTO	SEND_CARRY_ZERO
	
	BSF GPIO,GP4
	RETURN
SEND_CARRY_ZERO
	BCF GPIO,GP4
	RETURN
	
	

SEND_BYTE ; envia o byte que esta no W para o display via SPI
	MOVWF	BYTE
	; a frequencia do clock deve ser no maximo 50kHz
	; portanto o periodo minimo é de 20us (sera um pouco maior por precaucao)
	
	; ao rotacionar um file para a esquerda com RFL o bit mais significativo
	; é transportado para o carry (STATUS,C), entao isso será usado para 
	; determinar o bit a ser enviado para o display
	
	MOVLW	.9
	MOVWF	COUNTER 
SEND_BYTE_LOOP
	DECFSZ	COUNTER	
	GOTO	SEND_NEXT_BIT ; ira executar 8 vezes antes de ser pulado
	
	RETURN
	
SEND_NEXT_BIT
	RLF	BYTE	; bit mais significativo vai para o CARRY
	CALL	SEND_CARRY
	BCF	GPIO,GP0 
	CALL	LDELAY
	BSF	GPIO,GP0 
	GOTO	SEND_BYTE_LOOP
	
	
	
SEND_DATA   ; envia byte ao display usando o protocolo SPI
	MOVFW	BYTE1
	CALL	SEND_BYTE
	CALL	LDELAY
	CALL	LDELAY
	CALL	LDELAY
	CALL	LDELAY
	CALL	LDELAY
	CALL	LDELAY
	
	MOVFW	BYTE2
	CALL	SEND_BYTE
	CALL	LDELAY
	CALL	LDELAY
	CALL	LDELAY
	CALL	LDELAY
	CALL	LDELAY
	CALL	LDELAY
	
	MOVFW	CHECKSUM
	CALL	SEND_BYTE
	
	RETURN
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;*                     INICIO DO PROGRAMA                          *
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	
INICIO
	BANK1				;ALTERA PARA O BANCO 1
	MOVLW	B'00000110' ;CONFIGURA TODAS AS PORTAS DO GPIO (PINOS)
	MOVWF	TRISIO
	MOVLW	B'00010110'
	MOVWF	ANSEL ; CONFIGURA CONVERSOR A/D EM AN2 E ENTRADADO VREF EM AN1
	MOVLW	B'10000100'
	MOVWF	OPTION_REG	;DEFINE OPÇÕES DE OPERAÇÃO
	MOVLW	B'00000000'
	MOVWF	INTCON		;DEFINE OPÇÕES DE INTERRUPÇÕES
	CALL	3FFh
	MOVWF	OSCCAL
	BANK0				;RETORNA PARA O BANCO
	MOVLW	B'00000111'
	MOVWF	CMCON		;DEFINE O MODO DE OPERAÇÃO DO COMPARADOR ANALÓGICO
	MOVLW	B'11001001'
	MOVWF	ADCON0	; HABILITA E CONFIGURA CONVERSOR A/D NO CANAL 2, JUSTIFICADA A DIREITA


MAIN
	BSF	GPIO,GP0 ; em repouso
	CALL	HDELAY
	MOVLW	B'01000111'
	MOVWF	BYTE1
	MOVLW	B'01100011'
	MOVWF	BYTE2
	MOVLW	B'10101010'
	MOVWF	CHECKSUM
	;CALL	READ_TEMPERATURE
	;CALL	CALCULATE_BYTES
	CALL	SEND_DATA

	GOTO	MAIN

	END
