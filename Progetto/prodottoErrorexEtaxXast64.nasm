; ---------------------------------------------------------
; Regressione con istruzioni SSE a 32 bit
; ---------------------------------------------------------

%include "sseutils64.nasm"
section .data ;Sezione contenente dati inizializzati
;void prodottoErrorexEtaxXast(type* xast,type* pTheta,type* risultato,int dimTheta,type y,int offset)
	;xast			equ	 	 8 RDI
	;pTheta			equ		12 RSI
	;risultato      equ     16 RDX
	;dimTheta		equ		20 RCX
	;y       		equ     24 XMM0
	;offset	 		equ		28 R8

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
		push		rbp							; salva il Base Pointer
		mov			rbp, rsp					; il Base Pointer punta al Record di Attivazione corrente
		pushaq									; salva i registri generali
		; ------------------------------------------------------------
		; legge i parametri dal Record di Attivazione corrente
		; ------------------------------------------------------------
			;xast			equ	 	 8 RDI
			;pTheta			equ		12 RSI
			;risultato      equ     16 RDX
			;dimTheta		equ		20 RCX
			;y       		equ     24 XMM0
			;offset	 		equ		28 R8

		SHL R8,3
		ADD	RDI,R8				;xast[offset]
		MOV R12,RDI				;COPIA xast[offset]

		MOV R11,RCX				;COPIA DIMENSIONE TOTALE

		MOV R9,RCX
		SHR R9,2 				;MULTIPLI
		MOV R10,R9
		SHL R10,2
		SUB RCX,R10				;NON MULTIPLI

		VMOVSD XMM15,XMM0		;COPIA DI Y IN XMM15
		VXORPD YMM0,YMM0

;CASO MULTIPLO-----------------------------------------------------------------------------------------------------
forj:   CMP R9,0
        JE forisalto

		VMOVUPD YMM1,[RDI] 	   ;xast[offset+i]
		VMULPD  YMM1,[RSI]	   ;xast[offset+i]*pTheta[i];

		VADDPD  YMM0,YMM1	   ;ris+=pTheta[i]*xast[offset+i];

		ADD RDI,32					
		ADD RSI,32
		SUB R9,1

        JMP forj
;FINE CASO MULTIPLO--------------------------------------------------------------------------------------------------            
;CASO NON MULTIPLO---------------------------------------------------------------------------------------------------
forisalto:

		;VHADDPD YMM0,YMM0;SPOSTATE QUI DAVA PROBLEMI LA VMOVSD-VMULSD ------>>>>> SCALARE
		VPERM2F128 YMM10,YMM0,YMM0,00110011b; 00010001b ok 00000001b ok 00000011b ok 
		VHADDPD YMM0,YMM10
		VHADDPD YMM0,YMM0


fori:	CMP RCX,0
		JE forvexit

		VMOVSD  XMM1,[RDI] 	  ;xast[offset+i]
		VMULSD  XMM1,[RSI]	  ;xast[offset+i]*pTheta[i];

		VADDSD  XMM0,XMM1	  ;ris+=pTheta[i]*xast[offset+i];

		ADD RDI,8
		ADD RSI,8
		SUB RCX,1
		
		JMP fori
;FINE CASO NON MULTIPLO--------------------------------------------------------------------------------------------          
forvexit:


;-----------------------------------------------------------------------------------------------

		VSUBSD XMM0,XMM15			
		VUNPCKLPD XMM0,XMM0  							;[X,-,-,-]->[X,X,-,-]
		VPERM2F128  YMM0,YMM0,YMM0,00000000 ;modificato  [X,X,-,-]->[X,X,X,X]
;-----------------------------------------------------------------------------------------------	

		
		MOV R9,R11				;DIMENSIONE TOTALE

		SHR R9,2 				;MULTIPLI
		MOV R10,R9
		SHL R10,2
		SUB R11,R10				;NON MULTIPLI

;CASO MULTIPLO-----------------------------------------------------------------------------------------------------
forj1:  CMP R9,0
        JE fori1

		VMOVUPD YMM1,[R12]  	   ;xast[offset+i]
		VMULPD  YMM1,YMM0	       ;xast[offset+i]*ris;

		VADDPD  YMM1,[RDX]	       ;	
		VMOVUPD [RDX],YMM1	       ;risultato[i]+=xast[offset+i]*ris;
		
		ADD R12,32
		ADD RDX,32
		SUB R9,1

        JMP forj1
;FINE CASO MULTIPLO--------------------------------------------------------------------------------------------------            
;CASO NON MULTIPLO-------------------------------------------------------------------------------------------------
fori1:	CMP R11,0
		JE forvexit1

		VMOVSD XMM1,[R12]  	      ;xast[offset+i]
		VMULSD XMM1,XMM0	      ;xast[offset+i]*ris;

		VADDSD XMM1,[RDX]	      ;	
		VMOVSD [RDX],XMM1	 	  ;risultato[i]+=xast[offset+i]*ris;

		ADD R12,8
		ADD RDX,8
		SUB R11,1
		
		JMP fori1
;FINE CASO NON MULTIPLO--------------------------------------------------------------------------------------------          
forvexit1:


		; ------------------------------------------------------------
		; Sequenza di uscita dalla funzione
		; ------------------------------------------------------------

		popaq						; ripristina i registri generali
		mov		rsp, rbp			; ripristina lo Stack Pointer
		pop		rbp					; ripristina il Base Pointer
		ret							; torna alla funzione C chiamante