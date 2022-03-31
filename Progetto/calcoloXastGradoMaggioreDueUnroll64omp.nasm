; ---------------------------------------------------------
; Regressione con istruzioni SSE a 32 bit
; ---------------------------------------------------------

%include "sseutils64.nasm"

section .data			; Sezione contenente dati inizializzati
;void calcoloXastGradoMaggioreDueUnroll(type* x,int dim,int rig,int v[],int scarto,type* xast, int indiceXast,int grado,int t)
	;x			equ		8	RDI	
	;dim		equ		12	RSI
	;rig		equ		16	RDX	
	;v			equ		20	RCX
	;scarto		equ		24	R8
	;xast		equ		28	R9
	indiceXast	equ		16	
	grado 		equ		24
	t 			equ		32

align 32
ele1:		dq		1.0  
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


global calcoloXastGradoMaggioreDueUnroll

calcoloXastGradoMaggioreDueUnroll:
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
			;t 			equ		32
		IMUL RDX,RSI			;OFFSET = RIG*DIM
		SHL RSI,3				;DIM*8
		SHL RDX,3				;OFFSET*8
		ADD  RDX,RDI			;OFFSET*8 + BASE VETTORE X --> RDX = X[OFFSET]
		MOV R12,R8				;R12 = SCARTO
		MOV R10,[RBP+grado]		;R10 = GRADO
		SUB R10,R8				;R10 = GRADO-SCARTO
		MOV R11,R10				;R11 = GRADO-SCARTO

		SHR R10,2				;R10=(GRADO-SCARTO)/4)  		GESTIONE MULTIPLI
		MOV RBX,R10				;RBX=(GRADO-SCARTO)/4)
		SHL RBX,2				;RBX*4 	(((GRADO-SCARTO)/4)*4)	
		SUB R11,RBX				;GESTIONE NON MULTIPLI (GRADO-SCARTO)- (((GRADO-SCARTO)/4)*4)


		SHL R8,3
		ADD  RCX,R8			   	   ;BASE VETTORE V + SCARTO*8--> RCX = V[SCARTO]

		;VMOVSD [stampa],XMM0
		;printsd stampa

		VMOVSD XMM0,[ele1]         ; [1.0]

		VMOVSD XMM1,XMM0   	       ; [1.0]

		VMOVSD XMM2,XMM0    	   ; [1.0]
		VMOVSD XMM3,XMM1    	   ; [1.0]
		
		VMOVSD XMM4,XMM0    	   ; [1.0]
		VMOVSD XMM5,XMM1    	   ; [1.0]
		VMOVSD XMM6,XMM2     	   ; [1.0]
		VMOVSD XMM7,XMM3     	   ; [1.0]


;CASO NON MULTIPLO---------------------------------------------------------------------------------------------------


forj:	CMP R11,0
		JE fori
		;indice
		MOV R8,[RCX]
		SHL R8,3
		ADD R8,RDX

		MOV RBX,RSI

		VMULSD XMM0,[R8]
		VMULSD XMM1,[R8+RBX]
		ADD RBX,RSI
		VMULSD XMM2,[R8+RBX]
		ADD RBX,RSI
		VMULSD XMM3,[R8+RBX]
		ADD RBX,RSI
		VMULSD XMM4,[R8+RBX]
		ADD RBX,RSI
		VMULSD XMM5,[R8+RBX]
		ADD RBX,RSI
		VMULSD XMM6,[R8+RBX]
		ADD RBX,RSI
		VMULSD XMM7,[R8+RBX]

	
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
		ADD R8,RDX

		MOV RBX,RSI
	
		VMULSD XMM0,[R8]
		VMULSD XMM1,[R8+RBX]
		ADD RBX,RSI
		VMULSD XMM2,[R8+RBX]
		ADD RBX,RSI
		VMULSD XMM3,[R8+RBX]
		ADD RBX,RSI
		VMULSD XMM4,[R8+RBX]
		ADD RBX,RSI
		VMULSD XMM5,[R8+RBX]
		ADD RBX,RSI
		VMULSD XMM6,[R8+RBX]
		ADD RBX,RSI
		VMULSD XMM7,[R8+RBX]
		ADD RCX,8
	
;--------------------------------------------------------------------------------------------------------------------

		;indice
		MOV R8,[RCX]
		SHL R8,3
		ADD R8,RDX

		MOV RBX,RSI
	
		
		VMULSD XMM0,[R8]
		VMULSD XMM1,[R8+RBX]
		ADD RBX,RSI
		VMULSD XMM2,[R8+RBX]
		ADD RBX,RSI
		VMULSD XMM3,[R8+RBX]
		ADD RBX,RSI
		VMULSD XMM4,[R8+RBX]
		ADD RBX,RSI
		VMULSD XMM5,[R8+RBX]
		ADD RBX,RSI
		VMULSD XMM6,[R8+RBX]
		ADD RBX,RSI
		VMULSD XMM7,[R8+RBX]

		ADD RCX,8
	

;--------------------------------------------------------------------------------------------------------------------
		;indice
		MOV R8,[RCX]
		SHL R8,3
		ADD R8,RDX

		MOV RBX,RSI
	
		
		VMULSD XMM0,[R8]
		VMULSD XMM1,[R8+RBX]
		ADD RBX,RSI
		VMULSD XMM2,[R8+RBX]
		ADD RBX,RSI
		VMULSD XMM3,[R8+RBX]
		ADD RBX,RSI
		VMULSD XMM4,[R8+RBX]
		ADD RBX,RSI
		VMULSD XMM5,[R8+RBX]
		ADD RBX,RSI
		VMULSD XMM6,[R8+RBX]
		ADD RBX,RSI
		VMULSD XMM7,[R8+RBX]
		ADD RCX,8
	

;--------------------------------------------------------------------------------------------------------------------
		;indice
		MOV R8,[RCX]
		SHL R8,3
		ADD R8,RDX

		MOV RBX,RSI
	
		
		VMULSD XMM0,[R8]
		VMULSD XMM1,[R8+RBX]
		ADD RBX,RSI
		VMULSD XMM2,[R8+RBX]
		ADD RBX,RSI
		VMULSD XMM3,[R8+RBX]
		ADD RBX,RSI
		VMULSD XMM4,[R8+RBX]
		ADD RBX,RSI
		VMULSD XMM5,[R8+RBX]
		ADD RBX,RSI
		VMULSD XMM6,[R8+RBX]
		ADD RBX,RSI
		VMULSD XMM7,[R8+RBX]

		ADD RCX,8
		


;--------------------------------------------------------------------------------------------------------------------
					
		SUB R10,1

		JMP fori

finei:
		
;--------------------------------------------------------------------------------------------------------------------

		MOV RSI,[RBP+t] 		 ;NUMERO COLLONNE XAST da prendere dopo	
		SHL RSI,3
		MOV RDI,RSI

		MOV RBX,[RBP+indiceXast] ;
		SHL RBX,3				 ;INDICEXAST
		ADD R9,RBX

		 

		VMOVSD [R9],XMM0	  	 ;RISULTATO TOTALE PRODUTTORIA ---> xast[indiceXast]
		VMOVSD [R9+RSI],XMM1	 ;RISULTATO TOTALE PRODUTTORIA ---> xast[indiceXast+t]
		ADD RSI,RDI
		VMOVSD [R9+RSI],XMM2	 ;RISULTATO TOTALE PRODUTTORIA ---> xast[indiceXast+t*2]
		ADD RSI,RDI
		VMOVSD [R9+RSI],XMM3	 ;RISULTATO TOTALE PRODUTTORIA ---> xast[indiceXast+t*3]
		ADD RSI,RDI
		VMOVSD [R9+RSI],XMM4	 ;RISULTATO TOTALE PRODUTTORIA ---> xast[indiceXast+t*4]
		ADD RSI,RDI
		VMOVSD [R9+RSI],XMM5	 ;RISULTATO TOTALE PRODUTTORIA ---> xast[indiceXast+t*5]
		ADD RSI,RDI
		VMOVSD [R9+RSI],XMM6	 ;RISULTATO TOTALE PRODUTTORIA ---> xast[indiceXast+t*6]
		ADD RSI,RDI
		VMOVSD [R9+RSI],XMM7	 ;RISULTATO TOTALE PRODUTTORIA ---> xast[indiceXast+t*7]




;FINE CASO MULTIPLO--------------------------------------------------------------------------------------------------  		
		; ------------------------------------------------------------
		; Sequenza di uscita dalla funzione
		; ------------------------------------------------------------

		popaq						; ripristina i registri generali
		mov		rsp, rbp			; ripristina lo Stack Pointer
		pop		rbp					; ripristina il Base Pointer
		ret							; torna alla funzione C chiamante
