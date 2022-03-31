; ---------------------------------------------------------
; Regressione con istruzioni SSE a 32 bit
; ---------------------------------------------------------

%include "sseutils32.nasm"

section .data			; Sezione contenente dati inizializzati
;void inizializzaGradoUno(type* pxast,int rig,int dim,type* px,int indiceXast){
	pxast		equ	 	 8
	rig			equ		12
	dim			equ		16
	px			equ		20
	indiceXast  equ		24
		

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
		push		ebp							; salva il Base Pointer
		mov			ebp, esp					; il Base Pointer punta al Record di Attivazione corrente
		push		ebx							; salva i registri da preservare
		push		esi
		push		edi
		; ------------------------------------------------------------
		; legge i parametri dal Record di Attivazione corrente
		; ------------------------------------------------------------

		;void inizializzaGradoUno(type* pxast,int rig,int dim,type* px,int indiceXast){
		MOV EAX,[EBP+rig]
		MOV ESI,[EBP+dim]

		IMUL EAX,ESI 
		SHL EAX,2			     ;OFFSET = RIG*DIM
		ADD EAX,[EBP+px]		 ;BASE VETTORE PX + OFFSET; --> X[OFFSET]

		MOV ECX,[EBP+indiceXast] 
		SHL ECX,2				 ;OFFSET = INDICEXAST
		ADD ECX,[EBP+pxast]      ;BASE VETTORE PAXAST + OFFSET; --> PAXAST[OFFSET]

		MOV EDI,ESI
		SHR EDI,2 				 ;MULTIPLI
		MOV EBX,EDI
		SHL EBX,2
		SUB ESI,EBX		     	 ;NON MULTIPLI

;CASO MULTIPLO-----------------------------------------------------------------------------------------------------
forj:   CMP EDI,0
        JE fori

        MOVUPS XMM0,[EAX]	;		
		MOVUPS [ECX],XMM0	;DA CHIEDERE AL PROF MOVUPS	

		ADD EAX,16
		ADD ECX,16
		SUB EDI,1

        JMP forj
;FINE CASO MULTIPLO--------------------------------------------------------------------------------------------------            	

;CASO NON MULTIPLO-------------------------------------------------------------------------------------------------
fori:	CMP ESI,0
		JE forvexit
		
		MOVSS XMM0,[EAX]
		MOVSS[ECX],XMM0

		ADD EAX,4
		ADD ECX,4
		SUB ESI,1
		
		JMP fori
;FINE CASO NON MULTIPLO--------------------------------------------------------------------------------------------
forvexit:

		; ------------------------------------------------------------
		; Sequenza di uscita dalla funzione
		; ------------------------------------------------------------

		pop	edi									; ripristina i registri da preservare
		pop	esi
		pop	ebx
		mov	esp, ebp							; ripristina lo Stack Pointer
		pop	ebp									; ripristina il Base Pointer
		ret										; torna alla funzione C chiamante