; ---------------------------------------------------------
; Regressione con istruzioni SSE a 32 bit
; ---------------------------------------------------------

%include "sseutils64.nasm"


section .data			; Sezione contenente dati inizializzati
;void tuttiX(int v[], int x, int j,int grado)
;	v			equ	 	 8	RDI	
;	x			equ		12	RSI
;	j			equ		16	RDX
;	grado		equ		20	RCX

		

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



global tuttiX

tuttiX:
		; ------------------------------------------------------------
		; Sequenza di ingresso nella funzione
		; ------------------------------------------------------------
		push		rbp							; salva il Base Pointer
		mov			rbp, rsp					; il Base Pointer punta al Record di Attivazione corrente
		pushaq									; salva i registri generali
		; ------------------------------------------------------------
		; legge i parametri dal Record di Attivazione corrente
		; ------------------------------------------------------------

		
		;	v			equ	 	 8	RDI	
		;	x			equ		12	RSI
		;	j			equ		16	RDX
		;	grado		equ		20	RCX
			

fori:	CMP RCX,RDX
		JE forvexit

		MOV[RDI+RDX*8],RSI			;v[i] = x;
		ADD RDX,1

		JMP fori
		           
forvexit:
		
		; ------------------------------------------------------------
		; Sequenza di uscita dalla funzione
		; ------------------------------------------------------------

		popaq						; ripristina i registri generali
		mov		rsp, rbp			; ripristina lo Stack Pointer
		pop		rbp					; ripristina il Base Pointer
		ret							; torna alla funzione C chiamante