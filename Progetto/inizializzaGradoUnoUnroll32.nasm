; ---------------------------------------------------------
; Regressione con istruzioni SSE a 32 bit
; ---------------------------------------------------------

%include "sseutils32.nasm"

section .data			; Sezione contenente dati inizializzati
;void inizializzaGradoUno(type* pxast,int rig,int dim,type* px,int indiceXast),int t);
	pxast		equ	 	 8
	rig			equ		12
	dim			equ		16
	px			equ		20
	indiceXast  equ		24
	t 	   	    equ		28
		

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



global inizializzaGradoUnoUnroll

inizializzaGradoUnoUnroll:
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

		MOV EBX,[EBP+dim]
		SHL EBX,2
		MOV EDX,[EBP+t]
		SHL EDX,2

        MOVUPS XMM0,[EAX]			
		MOVUPS [ECX],XMM0	

		MOVUPS XMM1,[EAX+EBX]			
		MOVUPS [ECX+EDX],XMM1	

		MOVUPS XMM2,[EAX+EBX*2]			
		MOVUPS [ECX+EDX*2],XMM2		

		IMUL EBX,3
		IMUL EDX,3
		MOVUPS XMM3,[EAX+EBX]			
		MOVUPS [ECX+EDX],XMM3	

		MOV EBX,[EBP+dim]
		MOV EDX,[EBP+t]
		SHL EBX,2
		SHL EDX,2

		MOVUPS XMM4,[EAX+EBX*4]			
		MOVUPS [ECX+EDX*4],XMM4	

		IMUL EBX,5
		IMUL EDX,5
		MOVUPS XMM5,[EAX+EBX]			
		MOVUPS [ECX+EDX],XMM5		

		MOV EBX,[EBP+dim]
		MOV EDX,[EBP+t]
		SHL EBX,2
		SHL EDX,2

		IMUL EBX,6
		IMUL EDX,6
		MOVUPS XMM6,[EAX+EBX]			
		MOVUPS [ECX+EDX],XMM6		

		MOV EBX,[EBP+dim]
		MOV EDX,[EBP+t]
		SHL EBX,2
		SHL EDX,2
		IMUL EBX,7
		IMUL EDX,7

		MOVUPS XMM7,[EAX+EBX]			
		MOVUPS [ECX+EDX],XMM7	

		ADD EAX,16
		ADD ECX,16
		SUB EDI,1

        JMP forj
;FINE CASO MULTIPLO--------------------------------------------------------------------------------------------------            	

;CASO NON MULTIPLO-------------------------------------------------------------------------------------------------
fori:	CMP ESI,0
		JE forvexit

		MOV EBX,[EBP+dim]
		SHL EBX,2
		MOV EDX,[EBP+t]
		SHL EDX,2

        MOVSS XMM0,[EAX]			
		MOVSS [ECX],XMM0	

		MOVSS XMM1,[EAX+EBX]			
		MOVSS [ECX+EDX],XMM1	

		MOVSS XMM2,[EAX+EBX*2]			
		MOVSS [ECX+EDX*2],XMM2		

		IMUL EBX,3
		IMUL EDX,3
		MOVSS XMM3,[EAX+EBX]			
		MOVSS [ECX+EDX],XMM3	

		MOV EBX,[EBP+dim]
		MOV EDX,[EBP+t]
		SHL EBX,2
		SHL EDX,2

		MOVSS XMM4,[EAX+EBX*4]			
		MOVSS [ECX+EDX*4],XMM4	

		IMUL EBX,5
		IMUL EDX,5
		MOVSS XMM5,[EAX+EBX]			
		MOVSS [ECX+EDX],XMM5		

		MOV EBX,[EBP+dim]
		MOV EDX,[EBP+t]
		SHL EBX,2
		SHL EDX,2

		IMUL EBX,6
		IMUL EDX,6
		MOVSS XMM6,[EAX+EBX]			
		MOVSS [ECX+EDX],XMM6		

		MOV EBX,[EBP+dim]
		MOV EDX,[EBP+t]
		SHL EBX,2
		SHL EDX,2
		IMUL EBX,7
		IMUL EDX,7

		MOVSS XMM7,[EAX+EBX]			
		MOVSS [ECX+EDX],XMM7

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