; ---------------------------------------------------------
; Regressione con istruzioni SSE a 32 bit
; ---------------------------------------------------------

%include "sseutils64.nasm"

section .data			; Sezione contenente dati inizializzati
;void inizializzaGradoUno(type* pxast,int rig,int dim,type* px,int indiceXast){
	;pxast			equ	 	 8 RDI
	;rig			equ		12 RSI
	;dim			equ		16 RDX
	;px				equ		20 RCX
	;indiceXast  	equ		24 R8

		

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



global inizializzaGradoUno

inizializzaGradoUno:
		; ------------------------------------------------------------
		; Sequenza di ingresso nella funzione
		; ------------------------------------------------------------
		push		rbp							; salva il Base Pointer
		mov			rbp, rsp					; il Base Pointer punta al Record di Attivazione corrente
		pushaq									; salva i registri generali
		; ------------------------------------------------------------
		; legge i parametri dal Record di Attivazione corrente
		; ------------------------------------------------------------

		;void inizializzaGradoUno(type* pxast,int rig,int dim,type* px,int indiceXast){
				;pxast			equ	 	 8 RDI
				;rig			equ		12 RSI
				;dim			equ		16 RDX
				;px				equ		20 RCX
				;indiceXast  	equ		24 R8

		IMUL RSI,RDX 
		SHL RSI,3			     ;OFFSET = RIG*DIM
		ADD RSI,RCX				 ;BASE VETTORE PX + OFFSET; --> X[OFFSET]

		SHL R8,3				 ;OFFSET = INDICEXAST
		ADD R8,RDI     		     ;BASE VETTORE PAXAST + OFFSET; --> PXAST[OFFSET]

		MOV RAX,RDX
		SHR RAX,2 				 ;MULTIPLI
		MOV RBX,RAX
		SHL RBX,2
		SUB RDX,RBX		     	 ;NON MULTIPLI

;CASO MULTIPLO-----------------------------------------------------------------------------------------------------
forj:   CMP RAX,0
        JE fori

        VMOVUPD YMM0,[RSI]			
		VMOVUPD [R8],YMM0	

		ADD RSI,32
		ADD R8,32
		SUB RAX,1

        JMP forj
;FINE CASO MULTIPLO--------------------------------------------------------------------------------------------------            	

;CASO NON MULTIPLO-------------------------------------------------------------------------------------------------
fori:	CMP RDX,0
		JE forvexit
		
		VMOVSD XMM0,[RSI]
		VMOVSD [R8],XMM0

		ADD RSI,8
		ADD R8,8
		SUB RDX,1
		
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