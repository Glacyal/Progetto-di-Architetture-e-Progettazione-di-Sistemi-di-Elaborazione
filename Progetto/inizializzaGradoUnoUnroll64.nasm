; ---------------------------------------------------------
; Regressione con istruzioni SSE a 32 bit
; ---------------------------------------------------------

%include "sseutils64.nasm"

section .data			; Sezione contenente dati inizializzati
;void inizializzaGradoUno(type* pxast,int rig,int dim,type* px,int indiceXast),int t);
	;pxast			equ	 	 8 RDI
	;rig			equ		12 RSI
	;dim			equ		16 RDX
	;px				equ		20 RCX
	;indiceXast  	equ		24 R8
	;t 	   	   	    equ		28 R9


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
				;t 	   	   	    equ		28 R9

		MOV R10,RDX				 ;DIMENSIONE COPIA
		IMUL RSI,RDX 
		SHL RSI,3			     ;OFFSET = RIG*DIM
		ADD RSI,RCX				 ;BASE VETTORE PX + OFFSET; --> X[OFFSET]

		SHL R8,3				 ;OFFSET = INDICEXAST
		ADD R8,RDI        		 ;BASE VETTORE PAXAST + OFFSET; --> PAXAST[OFFSET]

		MOV RAX,RDX
		SHR RAX,2 				 ;MULTIPLI
		MOV RBX,RAX
		SHL RBX,2
		SUB RDX,RBX		     	 ;NON MULTIPLI



;CASO MULTIPLO-----------------------------------------------------------------------------------------------------
forj:   CMP RAX,0
        JE fori

		MOV RBX,R10
		SHL RBX,3
		MOV  R11,R9
		SHL R11,3
        VMOVUPD YMM0,[RSI]			
		VMOVUPD [R8],YMM0	

		VMOVUPD YMM1,[RSI+RBX]			
		VMOVUPD [R8+R11],YMM1	

		VMOVUPD YMM2,[RSI+RBX*2]			
		VMOVUPD [R8+R11*2],YMM2		

		IMUL RBX,3
		IMUL R11,3
		VMOVUPD YMM3,[RSI+RBX]			
		VMOVUPD [R8+R11],YMM3	

		MOV RBX,R10
		MOV R11,R9
		SHL RBX,3
		SHL R11,3

		VMOVUPD YMM4,[RSI+RBX*4]			
		VMOVUPD [R8+R11*4],YMM4	

		IMUL RBX,5
		IMUL R11,5
		VMOVUPD YMM5,[RSI+RBX]			
		VMOVUPD [R8+R11],YMM5		


		MOV RBX,R10
		MOV R11,R9
		SHL RBX,3
		SHL R11,3

		IMUL RBX,6
		IMUL R11,6
		VMOVUPD YMM6,[RSI+RBX]			
		VMOVUPD [R8+R11],YMM6		


		MOV RBX,R10
		MOV R11,R9
		SHL RBX,3
		SHL R11,3

		IMUL RBX,7
		IMUL R11,7

		VMOVUPD YMM7,[RSI+RBX]			
		VMOVUPD [R8+R11],YMM7	

		ADD RSI,32
		ADD R8,32
		SUB RAX,1

        JMP forj
;FINE CASO MULTIPLO--------------------------------------------------------------------------------------------------            	

;CASO NON MULTIPLO-------------------------------------------------------------------------------------------------
fori:	CMP RDX,0
		JE forvexit

		MOV RBX,R10
		SHL RBX,3
		MOV  R11,R9
		SHL R11,3

        VMOVSD XMM0,[RSI]			
		VMOVSD [R8],XMM0	

		VMOVSD XMM1,[RSI+RBX]			
		VMOVSD [R8+R11],XMM1	

		VMOVSD XMM2,[RSI+RBX*2]			
		VMOVSD [R8+R11*2],XMM2		

		IMUL RBX,3
		IMUL R11,3
		VMOVSD XMM3,[RSI+RBX]			
		VMOVSD [R8+R11],XMM3	

		MOV RBX,R10
		MOV R11,R9
		SHL RBX,3
		SHL R11,3

		VMOVSD XMM4,[RSI+RBX*4]			
		VMOVSD [R8+R11*4],XMM4	

		IMUL RBX,5
		IMUL R11,5
		VMOVSD XMM5,[RSI+RBX]			
		VMOVSD [R8+R11],XMM5		


		MOV RBX,R10
		MOV R11,R9
		SHL RBX,3
		SHL R11,3

		IMUL RBX,6
		IMUL R11,6
		VMOVSD XMM6,[RSI+RBX]			
		VMOVSD [R8+R11],XMM6		


		MOV RBX,R10
		MOV R11,R9
		SHL RBX,3
		SHL R11,3

		IMUL RBX,7
		IMUL R11,7

		VMOVSD XMM7,[RSI+RBX]			
		VMOVSD [R8+R11],XMM7	

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