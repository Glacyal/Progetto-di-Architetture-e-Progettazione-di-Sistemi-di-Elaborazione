; ---------------------------------------------------------
; Regressione con istruzioni SSE a 32 bit
; ---------------------------------------------------------

%include "sseutils64.nasm"

section .data			; Sezione contenente dati inizializzati
;void calcoloXastGradoMaggioreDue(type* x,int dim,int rig,int v[],int scarto,type* xast, int indiceXast,int grado)
	;x			equ		8	RDI	
	;dim		equ		12	RSI
	;rig		equ		16	RDX	
	;v			equ		20	RCX
	;scarto		equ		24	R8
	;xast		equ		28	R9
	indiceXast	equ		16	
	grado 		equ		24


	
align 32
tutti1:		dq		1.0
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


global calcoloXastGradoMaggioreDue

calcoloXastGradoMaggioreDue:
		; ------------------------------------------------------------
		; Sequenza di ingresso nella funzione
		; ------------------------------------------------------------
		push		rbp							; salva il Base Pointer
		mov			rbp, rsp					; il Base Pointer punta al Record di Attivazione corrente
		pushaq									; salva i registri generali
		; ------------------------------------------------------------
		; legge i parametri dal Record di Attivazione corrente
		; ------------------------------------------------------------
			;x			equ		8	RDI	
			;dim		equ		12	RSI
			;rig		equ		16	RDX	
			;v			equ		20	RCX
			;scarto		equ		24	R8
			;xast		equ		28	R9
			;indiceXast	equ		16	
			;grado 		equ		24
		
		IMUL RDX,RSI			;
		SHL RDX,3				;OFFSET = RIG*DIM
		ADD  RDX,RDI			;BASE VETTORE X + OFFSET; --> X[OFFSET]

		MOV R10,[RBP+grado]
		SUB R10,R8				;GRADO-SCARTO
		MOV R11,R10				;COPIA (GRADO-SCARTO)

		SHR R10,2				;GESTIONE MULTIPLI (GRADO-SCARTO)/4)
		MOV RBX,R10				;COPIA (GRADO-SCARTO)/4)
		SHL RBX,2				;(((GRADO-SCARTO)/4)*4)	
		SUB R11,RBX				;GESTIONE NON MULTIPLI (GRADO-SCARTO)- (((GRADO-SCARTO)/4)*4)


		SHL R8,3				;SCARTO*(?)
		ADD  RCX,R8				;BASE VETTORE V + SCARTO ---> v[SCARTO];
		
		VMOVSD XMM1,[tutti1]    ; [1.0]

;CASO NON MULTIPLO---------------------------------------------------------------------------------------------------
forj:	CMP R11,0
		JE fori

		;indice

		MOV R8,[RCX]
		SHL R8,3
		VMULSD XMM1,[RDX+R8]

		ADD RCX,8
		SUB R11,1
		

		JMP forj
;FINE CASO NON MULTIPLO----------------------------------------------------------------------------------------------
;CASO MULTIPLO-------------------------------------------------------------------------------------------------------
fori:   CMP R10,0
		JE finei
		
		;indice
		MOV R8,[RCX]
		SHL R8,3
		VMULSD XMM1,[RDX+R8]

		ADD RCX,8
	
;--------------------------------------------------------------------------------------------------------------------
		MOV R8,[RCX]
		SHL R8,3
		VMULSD XMM1,[RDX+R8]

		ADD RCX,8

;--------------------------------------------------------------------------------------------------------------------
		MOV R8,[RCX]
		SHL R8,3
		VMULSD XMM1,[RDX+R8]

		ADD RCX,8

;--------------------------------------------------------------------------------------------------------------------
		MOV R8,[RCX]
		SHL R8,3
		VMULSD XMM1,[RDX+R8]

		ADD RCX,8

;--------------------------------------------------------------------------------------------------------------------
					
		SUB R10,1
		JMP fori

finei:
		
;--------------------------------------------------------------------------------------------------------------------		

		MOV RBX,[RBP+indiceXast] ;
		SHL RBX,3				 ;INDICEXAST
		VMOVSD [R9+RBX],XMM1	 ;RISULTATO TOTALE PRODUTTORIA ---> xast[indiceXast]

;FINE CASO MULTIPLO--------------------------------------------------------------------------------------------------  		
		; ------------------------------------------------------------
		; Sequenza di uscita dalla funzione
		; ------------------------------------------------------------

		popaq						; ripristina i registri generali
		mov		rsp, rbp			; ripristina lo Stack Pointer
		pop		rbp					; ripristina il Base Pointer
		ret							; torna alla funzione C chiamante
