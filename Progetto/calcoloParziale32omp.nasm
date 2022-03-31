; ---------------------------------------------------------
; Regressione con istruzioni SSE a 32 bit
; ---------------------------------------------------------

%include "sseutils32.nasm"
section .data ;Sezione contenente dati inizializzati
;void calcoloParziale(type* pxast,type* pTheta,type* Gj,int dimTheta,type y,
					  ;int offset,int offsetPxast,type eta,type eps,type* risultato)
	pxast			equ	 	 8
	pTheta			equ		12
	Gj      	    equ     16
	dimTheta		equ		20
	y       		equ     24
	offset	 		equ		28
	offsetPxast	 	equ		32
	eta	 			equ		36
	eps	 			equ		40
	risultato	 	equ		44
	

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
global calcoloParziale

calcoloParziale:
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
		MOV EAX,[EBP+pxast]    	;BASE VETTORE xast
		MOV EBX,[EBP+pTheta]	;BASE VETTORE pTheta
														
		MOV ESI,[EBP+dimTheta]	;DIMENSIONE TOTALE
		MOV EDX,[EBP+offsetPxast]
		SHL EDX,2
		ADD  EAX,EDX 	  	;xast[offsetPxast]
		
		MOV EDI,ESI
		SHR EDI,2 			;MULTIPLI
		MOV ECX,EDI
		SHL ECX,2
		SUB ESI,ECX			;NON MULTIPLI

		XOR ECX,ECX
		
		XORPS XMM0,XMM0

;CASO MULTIPLO-----------------------------------------------------------------------------------------------------
forj:   CMP EDI,0
        JE fori

		MOVUPS XMM1,[EAX] 	   ;xast[offsetPxast+i]
		MULPS  XMM1,[EBX]	   ;xast[offsetPxast+i]*pTheta[i];

		ADDPS  XMM0,XMM1	   ;ris+=pTheta[i]*xast[offsetPxast+i];

		ADD EAX,16					
		ADD EBX,16
		SUB EDI,1

        JMP forj
;FINE CASO MULTIPLO--------------------------------------------------------------------------------------------------            
;CASO NON MULTIPLO-------------------------------------------------------------------------------------------------
fori:	CMP ESI,0
		JE forvexit

		MOVSS  XMM1,[EAX] 	  ;xast[offsetPxast+i]
		MULSS  XMM1,[EBX]	  ;xast[offsetPxast+i]*pTheta[i];
		
		ADDSS  XMM0,XMM1	  ;ris+=pTheta[i]*xast[offsetPxast+i];

		ADD EAX,4
		ADD EBX,4
		SUB ESI,1
		
		JMP fori
;FINE CASO NON MULTIPLO--------------------------------------------------------------------------------------------          
forvexit:
		HADDPS XMM0,XMM0
		HADDPS XMM0,XMM0

;-----------------------------------------------------------------------------------------------		
		SUBSS XMM0,[EBP+y]
		SHUFPS XMM0,XMM0,00000000b
;-----------------------------------------------------------------------------------------------	
		MOV  EAX,[EBP+pxast]    ;BASE VETTORE xast
		ADD  EAX,EDX 	  		;xast[offsetPxast]	

		MOV  ECX,[EBP+offset]	;
		SHL ECX,2				;OFFSET
									
		MOV EDX,[EBP+Gj]
		ADD EDX,ECX
		
		MOV EBX,[EBP+risultato]


		MOVSS XMM6,[EBP+eta]
		SHUFPS XMM6,XMM6,00000000b

		MOVSS XMM7,[EBP+eps]
		SHUFPS XMM7,XMM7,00000000b

		MOV ESI,[EBP+dimTheta]	;DIMENSIONE TOTALE
		MOV EDI,ESI
		SHR EDI,2 				;MULTIPLI
		MOV ECX,EDI
		SHL ECX,2
		SUB ESI,ECX				;NON MULTIPLI
		

;CASO MULTIPLO-----------------------------------------------------------------------------------------------------
forj1:  CMP EDI,0
        JE fori1

		MOVUPS XMM1,[EAX]   ;xast[offsetPxast+i]
		MULPS  XMM1,XMM0	;xast[offsetPxast+i]*ris;

		MOVAPS XMM2,XMM1	;gj--->>COPIA
		MULPS  XMM2,XMM2	;gj*gj
		MOVUPS XMM3,[EDX]	;Gj[off] vecchio
		ADDPS  XMM3,XMM2	;Gj[off] + gj*gj
		MOVUPS [EDX],XMM3	;Gj[off] nuovo

		MULPS XMM1,XMM6		;gj = gj*eta
		ADDPS XMM3,XMM7		;sqrtrad = Gj[off]+eps
		SQRTPS XMM3,XMM3	;radice = sqrt(sqrtrad)

		DIVPS XMM1,XMM3		;(gj*eta/radice)
		MOVUPS XMM5,[EBX]	;risultato[i] vecchio
		ADDPS  XMM5,XMM1	;risultato[i]+(gj*eta/radice)
		MOVUPS [EBX],XMM5	;risultato[i] nuovo
		
		ADD EAX,16
		ADD EBX,16
		ADD EDX,16
		SUB EDI,1

        JMP forj1
;FINE CASO MULTIPLO--------------------------------------------------------------------------------------------------            
;CASO NON MULTIPLO-------------------------------------------------------------------------------------------------
fori1:	CMP ESI,0
		JE forvexit1

		MOVSS XMM1,[EAX]    ;xast[offsetPxast+i]
		MULSS  XMM1,XMM0	;xast[offsetPxast+i]*ris;

		MOVSS XMM2,XMM1		;gj--->>COPIA
		MULSS  XMM2,XMM2	;gj*gj
		MOVSS XMM3,[EDX]	;Gj[off] vecchio
		ADDSS  XMM3,XMM2	;Gj[off] + gj*gj
		MOVSS [EDX],XMM3	;Gj[off] nuovo

		MULSS XMM1,XMM6		;gj = gj*eta
		ADDSS XMM3,XMM7		;sqrtrad = Gj[off]+eps
		SQRTSS XMM3,XMM3	;radice = sqrt(sqrtrad)

		DIVSS XMM1,XMM3		;(gj*eta/radice)
		MOVSS XMM5,[EBX]	;risultato[i] vecchio
		ADDSS XMM5,XMM1		;risultato[i]+(gj*eta/radice)
		MOVSS [EBX],XMM5	;risultato[i] nuovo
		
		ADD EAX,4
		ADD EBX,4
		ADD EDX,4
		SUB ESI,1
		
		JMP fori1
;FINE CASO NON MULTIPLO--------------------------------------------------------------------------------------------          
forvexit1:


		; ------------------------------------------------------------
		; Sequenza di uscita dalla funzione
		; ------------------------------------------------------------

		pop	edi									; ripristina i registri da preservare
		pop	esi
		pop	ebx
		mov	esp, ebp							; ripristina lo Stack Pointer
		pop	ebp									; ripristina il Base Pointer
		ret										; torna alla funzione C chiamante