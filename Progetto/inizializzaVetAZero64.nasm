; ---------------------------------------------------------
; Regressione con istruzioni SSE a 32 bit
; ---------------------------------------------------------

%include "sseutils64.nasm"

section .data			; Sezione contenente dati inizializzati
;void inizializzaVetAZero(type* vett,int dimTheta){
	;vett		equ	 	 8  RDI
	;dimTheta	equ		12  RSI
	
section .bss
section .text			; Sezione contenente il codice macchina


; ----------------------------------------------------------
; macro per l'allocazione dinamica della memoria
;
;	getmem	<size>,<elements>
;
; alloca un'area di memoria di <size>*<elements> bytes
; (allineata a 16 bytes) e restituisce in EAX
; l'indirizzo del primo bytes del blocco allocato
; (funziona mediante chiamata a funzione C, per cui
; altri registri potrebbero essere modificati)
;
;	fremem	<address>
;
; dealloca l'area di memoria che ha inizio dall'indirizzo
; <address> precedentemente allocata con getmem
; (funziona mediante chiamata a funzione C, per cui
; altri registri potrebbero essere modificati)




; ------------------------------------------------------------
; Funzioni
; ------------------------------------------------------------



global inizializzaVetAZero

inizializzaVetAZero:
		; ------------------------------------------------------------
		; Sequenza di ingresso nella funzione
		; ------------------------------------------------------------
		push		rbp							; salva il Base Pointer
		mov			rbp, rsp					; il Base Pointer punta al Record di Attivazione corrente
		pushaq									; salva i registri generali
		; ------------------------------------------------------------
		; legge i parametri dal Record di Attivazione corrente
		; ------------------------------------------------------------
	
		MOV RBX,RSI
		SHR RBX,2 			;MULTIPLI
		MOV RCX,RBX
		SHL RCX,2
		SUB RSI,RCX			;NON MULTIPLI

		VXORPS YMM0,YMM0
		;vett		equ	 	 8  RDI ;BASE VETTORE
	 	;dimTheta	equ		12  RSI ;DIMENSIONE TOTALE

;CASO MULTIPLO-----------------------------------------------------------------------------------------------------
forj:   CMP RBX,0
        JE fori
			
		VMOVAPD[RDI],YMM0	

		ADD RDI,32
		SUB RBX,1

        JMP forj
;FINE CASO MULTIPLO--------------------------------------------------------------------------------------------------            
;CASO NON MULTIPLO-------------------------------------------------------------------------------------------------
fori:	CMP RSI,0
		JE forvexit
		
		VMOVSD[RDI],XMM0

		ADD RDI,8
		SUB RSI,1
		
		JMP fori
;FINE CASO NON MULTIPLO--------------------------------------------------------------------------------------------          
forvexit:
	
		; ------------------------------------------------------------
		; Sequenza di uscita dalla funzione
		; ------------------------------------------------------------

		popaq						; ripristina i registri generali
		mov		rsp, rbp			; ripristina lo Stack Pointer
		pop		rbp					; ripristina il Base Pointer
		ret							; torna alla funzione C chiamante