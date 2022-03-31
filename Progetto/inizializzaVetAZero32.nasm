; ---------------------------------------------------------
; Regressione con istruzioni SSE a 32 bit
; ---------------------------------------------------------

%include "sseutils32.nasm"

section .data			; Sezione contenente dati inizializzati
;void inizializzaVetAZero(type* vett,int dimTheta){
	vett		equ	 	 8
	dimTheta	equ		12

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
		push		ebp							; salva il Base Pointer
		mov			ebp, esp					; il Base Pointer punta al Record di Attivazione corrente
		push		ebx							; salva i registri da preservare
		push		esi
		push		edi
		; ------------------------------------------------------------
		; legge i parametri dal Record di Attivazione corrente
		; ------------------------------------------------------------

		MOV EAX,[EBP+vett]      ;BASE VETTORE
		MOV ESI,[EBP+dimTheta]	;DIMENSIONE TOTALE
	
		MOV EDI,ESI
		SHR EDI,2 			;MULTIPLI
		MOV ECX,EDI
		SHL ECX,2
		SUB ESI,ECX			;NON MULTIPLI

		XORPS XMM0,XMM0


;CASO MULTIPLO-----------------------------------------------------------------------------------------------------
forj:   CMP EDI,0
        JE fori
			
		MOVAPS[EAX],XMM0	

		ADD EAX,16
		SUB EDI,1

        JMP forj
;FINE CASO MULTIPLO--------------------------------------------------------------------------------------------------            
;CASO NON MULTIPLO-------------------------------------------------------------------------------------------------
fori:	CMP ESI,0
		JE forvexit

		;MOVSS[stampa],XMM0
		;printps stampa,1
		
		MOVSS[EAX],XMM0

		ADD EAX,4
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