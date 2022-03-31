; ---------------------------------------------------------
; Regressione con istruzioni SSE a 32 bit
; ---------------------------------------------------------

%include "sseutils32.nasm"
section .data ;Sezione contenente dati inizializzati
;void prodottoErrorexEtaxXast(type* xast,type* pTheta,type* risultato,int dimTheta,type y,int offset)
	xast			equ	 	 8
	pTheta			equ		12
	risultato       equ     16
	dimTheta		equ		20
	y       		equ     24
	offset	 		equ		28

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



global prodottoErrorexEtaxXast

prodottoErrorexEtaxXast:
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
		MOV EAX,[EBP+xast]    	;BASE VETTORE xast
		MOV EBX,[EBP+pTheta]	;BASE VETTORE pTheta
														
		MOV ESI,[EBP+dimTheta]	;DIMENSIONE TOTALE
		MOV EDX,[EBP+offset]
		SHL EDX,2
		ADD	EAX,EDX				;xast[offset]

		MOV EDI,ESI
		SHR EDI,2 				;MULTIPLI
		MOV ECX,EDI
		SHL ECX,2
		SUB ESI,ECX				;NON MULTIPLI
		
		XORPS XMM0,XMM0

;CASO MULTIPLO-----------------------------------------------------------------------------------------------------
forj:   CMP EDI,0
        JE fori

		MOVUPS XMM1,[EAX] 	   ;xast[offset+i]
		MULPS  XMM1,[EBX]	   ;xast[offset+i]*pTheta[i];

		ADDPS  XMM0,XMM1		   ;ris+=pTheta[i]*xast[offset+i];

		ADD EAX,16					
		ADD EBX,16
		SUB EDI,1

        JMP forj
;FINE CASO MULTIPLO--------------------------------------------------------------------------------------------------            
;CASO NON MULTIPLO-------------------------------------------------------------------------------------------------
fori:	CMP ESI,0
		JE forvexit

		MOVSS  XMM1,[EAX] 	  ;xast[offset+i]
		MULSS  XMM1,[EBX]	  ;xast[offset+i]*pTheta[i];

		ADDSS  XMM0,XMM1	  ;ris+=pTheta[i]*xast[offset+i];

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

		MOV EAX,[EBP+xast]    	;BASE VETTORE xast
		MOV EBX,[EBP+risultato]	;BASE VETTORE risultato

		ADD	EAX,EDX				;xast[offset]



		MOV ESI,[EBP+dimTheta]	;DIMENSIONE TOTALE
		MOV EDI,ESI
		SHR EDI,2 				;MULTIPLI
		MOV ECX,EDI
		SHL ECX,2
		SUB ESI,ECX				;NON MULTIPLI

;CASO MULTIPLO-----------------------------------------------------------------------------------------------------
forj1:  CMP EDI,0
        JE fori1

		MOVUPS XMM1,[EAX]  	  	   ;xast[offset+i]
		MULPS  XMM1,XMM0	       ;xast[offset+i]*ris;

		ADDPS  XMM1,[EBX]	       ;	
		MOVUPS [EBX],XMM1	       ;risultato[i]+=xast[offset+i]*ris;
		
		ADD EAX,16
		ADD EBX,16
		SUB EDI,1

        JMP forj1
;FINE CASO MULTIPLO--------------------------------------------------------------------------------------------------            
;CASO NON MULTIPLO-------------------------------------------------------------------------------------------------
fori1:	CMP ESI,0
		JE forvexit1

		MOVSS XMM1,[EAX]  	      ;xast[offset+i]
		MULSS XMM1,XMM0	     	  ;xast[offset+i]*ris;

		ADDSS XMM1,[EBX]	      ;	
		MOVSS [EBX],XMM1	 	  ;risultato[i]+=xast[offset+i]*ris;

		ADD EAX,4
		ADD EBX,4
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