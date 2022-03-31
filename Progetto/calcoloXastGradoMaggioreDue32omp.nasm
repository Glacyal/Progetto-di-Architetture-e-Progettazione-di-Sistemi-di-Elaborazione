; ---------------------------------------------------------
; Regressione con istruzioni SSE a 32 bit
; ---------------------------------------------------------

%include "sseutils32.nasm"

section .data			; Sezione contenente dati inizializzati
;void calcoloXastGradoMaggioreDue(type* x,int dim,int rig,int v[],int scarto,type* xast, int indiceXast,int grado)
	x		equ		8
	dim		equ		12
	rig		equ		16
	v		equ		20
	scarto	equ		24
	xast	equ		28
	indiceXast	equ	32
	grado 		equ	36

	
align 16
tutti1:		dd		1.0

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
		push		ebp							; salva il Base Pointer
		mov			ebp, esp					; il Base Pointer punta al Record di Attivazione corrente
		push		ebx							; salva i registri da preservare
		push		esi
		push		edi
		; ------------------------------------------------------------
		; legge i parametri dal Record di Attivazione corrente
		; ------------------------------------------------------------
		
	
		MOV EAX,[EBP+rig]
		MOV EBX,[EBP+dim] 
		MOV ECX,[EBP+scarto]
		MOV EDX,[EBP+v]			;BASE VETTORE V
		MOV EDI,[EBP+grado]

		IMUL EAX,EBX			;
		SHL  EAX,2				;OFFSET = RIG*DIM
		ADD  EAX,[EBP+x]		;BASE VETTORE X + OFFSET; --> X[OFFSET]

		
		SUB EDI,ECX				;GRADO-SCARTO
		MOV ESI,EDI 			;COPIA (GRADO-SCARTO)

		SHR EDI,2				;GESTIONE MULTIPLI (GRADO-SCARTO)/4)
		MOV EBX,EDI				;COPIA (GRADO-SCARTO)/4)
		SHL EBX,2				;(((GRADO-SCARTO)/4)*4)	
		SUB ESI,EBX				;GESTIONE NON MULTIPLI (GRADO-SCARTO)- (((GRADO-SCARTO)/4)*4)


		SHL ECX,2
		ADD EDX,ECX
		
		MOVSS XMM1,[tutti1]    ; [1.0]
		
;CASO NON MULTIPLO---------------------------------------------------------------------------------------------------
forj:	CMP ESI,0
		JE fori

		;indice
		MOV ECX,[EDX]
		SHL ECX,2
		
	
		MULSS XMM1,[EAX+ECX]
	
		ADD EDX,4
		SUB ESI,1
	

		JMP forj
;FINE CASO NON MULTIPLO----------------------------------------------------------------------------------------------
;CASO MULTIPLO-------------------------------------------------------------------------------------------------------
fori:   CMP EDI,0
		JE finei
		
		;indice
		MOV ECX,[EDX]
		SHL ECX,2
		MULSS XMM1,[EAX+ECX]

		ADD EDX,4
	
;--------------------------------------------------------------------------------------------------------------------
		MOV ECX,[EDX]
		SHL ECX,2
		MULSS XMM1,[EAX+ECX]

		ADD EDX,4

;--------------------------------------------------------------------------------------------------------------------
		MOV ECX,[EDX]
		SHL ECX,2

		MULSS XMM1,[EAX+ECX]

		ADD EDX,4

;--------------------------------------------------------------------------------------------------------------------
		MOV ECX,[EDX]
		SHL ECX,2

		MULSS XMM1,[EAX+ECX]

		ADD EDX,4


;--------------------------------------------------------------------------------------------------------------------
					
		SUB EDI,1
		JMP fori

finei:
		
;--------------------------------------------------------------------------------------------------------------------		
		
		MOV EAX,[EBP+xast]		 ;BASE VETTORE XAST
		MOV EBX,[EBP+indiceXast] ;
		SHL EBX,2				 ;INDICEXAST
		MOVSS [EAX+EBX],XMM1	 ;RISULTATO TOTALE PRODUTTORIA ---> xast[indiceXast]
;FINE CASO MULTIPLO--------------------------------------------------------------------------------------------------  		
		; ------------------------------------------------------------
		; Sequenza di uscita dalla funzione
		; ------------------------------------------------------------

		pop	edi									; ripristina i registri da preservare
		pop	esi
		pop	ebx
		mov	esp, ebp							; ripristina lo Stack Pointer
		pop	ebp									; ripristina il Base Pointer
		ret										; torna alla funzione C chiamante
