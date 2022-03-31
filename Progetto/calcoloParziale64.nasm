; ---------------------------------------------------------
; Regressione con istruzioni SSE a 32 bit
; ---------------------------------------------------------

%include "sseutils64.nasm"
section .data ;Sezione contenente dati inizializzati
;void calcoloParziale(type* pxast,type* pTheta,type* Gj,int dimTheta,type y,
					  ;int offset,int offsetPxast,type eta,type eps,type* risultato)
	;pxast			equ	 	RDI
	;pTheta			equ		RSI
	;Gj      	    equ     RDX
	;dimTheta		equ		RCX
	;y       		equ     XMM0
	;offset	 		equ		R8
	;offsetPxast 	equ		R9
	;eta	 		equ	    XMM1
	;eps	 		equ	    XMM2
	risultato	 	equ		16

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
		push		rbp							; salva il Base Pointer
		mov			rbp, rsp					; il Base Pointer punta al Record di Attivazione corrente
		pushaq									; salva i registri generali
		; ------------------------------------------------------------
		; legge i parametri dal Record di Attivazione corrente
		; ------------------------------------------------------------
			;pxast			equ	 	RDI
			;pTheta			equ		RSI
			;Gj      	    equ     RDX
			;dimTheta		equ		RCX
			;y       		equ     XMM0
			;offset	 		equ		R8
			;offsetPxast 	equ		R9
			;eta	 		equ	    XMM1
			;eps	 		equ	    XMM2
			;risultato	 	equ		16

		SHL R9,3
		ADD RDI,R9 	  		;xast[offsetPxast]
		
		MOV R12,RCX			;COPIA dimTheta
		MOV R13,RDI			;COPIA xast[offsetPxast]
		
		MOV R10,RCX
		SHR R10,2 			;MULTIPLI
		MOV R11,R10
		SHL R11,2
		SUB RCX,R11			;NON MULTIPLI

		XOR R11,R11
		
		VXORPD YMM3,YMM3

;CASO MULTIPLO-----------------------------------------------------------------------------------------------------
forj:   CMP R10,0
        JE forjexit

		VMOVUPD YMM4,[RDI] 	   ;xast[offsetPxast+i]
		VMULPD  YMM4,[RSI]	   ;xast[offsetPxast+i]*pTheta[i];

		VADDPD  YMM3,YMM4	   ;ris+=pTheta[i]*xast[offsetPxast+i];

		ADD RDI,32					
		ADD RSI,32
		SUB R10,1

        JMP forj
;FINE CASO MULTIPLO--------------------------------------------------------------------------------------------------   
forjexit:
		VPERM2F128 YMM10,YMM3,YMM3,00110011b; 00010001b ok 00000001b ok 00000011b ok 

		VHADDPD YMM3,YMM10
		VHADDPD YMM3,YMM3

;CASO NON MULTIPLO-------------------------------------------------------------------------------------------------
fori:	CMP RCX,0
		JE forvexit

		VMOVSD  XMM4,[RDI] 	  ;xast[offsetPxast+i]
		VMULSD  XMM4,[RSI]	  ;xast[offsetPxast+i]*pTheta[i];
		
		VADDSD  XMM3,XMM4	  ;ris+=pTheta[i]*xast[offsetPxast+i];

		ADD RDI,8
		ADD RSI,8
		SUB RCX,1
		
		JMP fori
;FINE CASO NON MULTIPLO--------------------------------------------------------------------------------------------          
forvexit:
;-----------------------------------------------------------------------------------------------
		VSUBSD XMM3,XMM0
		VUNPCKLPD XMM3,XMM3								;[X,X,-,-]->[X,X,X,X]
		VPERM2F128  YMM3,YMM3,YMM3,00000000 ;modificato	 [X,X,-,-]->[X,X,X,X]

;-----------------------------------------------------------------------------------------------	

		SHL R8,3				 ;OFFSET								
		ADD RDX,R8				 ;Gj[offset]


		VUNPCKLPD XMM1,XMM1
		VPERM2F128  YMM1,YMM1,YMM1,00000000 ;modificato

		VUNPCKLPD XMM2,XMM2
		VPERM2F128  YMM2,YMM2,YMM2,00000000 ;modificato
		
		MOV R10,R12
		SHR R10,2 				;MULTIPLI
		MOV R11,R10
		SHL R11,2
		SUB R12,R11				;NON MULTIPLI
		
		MOV R14,[RBP+risultato]
;CASO MULTIPLO-----------------------------------------------------------------------------------------------------
forj1:  CMP R10,0
        JE fori1

		VMOVUPD YMM4,[R13]  ;xast[offsetPxast+i]
		VMULPD  YMM4,YMM3	;xast[offsetPxast+i]*(ris-y);

		VMOVAPD YMM5,YMM4	;gj--->>COPIA
		VMULPD  YMM5,YMM5	;gj*gj
		VMOVUPD YMM6,[RDX]	;Gj[off] vecchio
		VADDPD  YMM6,YMM5	;Gj[off] + gj*gj
		VMOVUPD [RDX],YMM6	;Gj[off] nuovo

		VMULPD YMM4,YMM1	;gj = gj*eta
		VADDPD YMM6,YMM2	;sqrtrad = Gj[off]+eps
		VSQRTPD YMM6,YMM6	;radice = sqrt(sqrtrad)

		VDIVPD YMM4,YMM6	;(gj*eta/radice)
		VMOVUPD YMM7,[R14]	;risultato[i] vecchio
		VADDPD  YMM7,YMM4	;risultato[i]+(gj*eta/radice)
		VMOVUPD [R14],YMM7	;risultato[i] nuovo
		
		ADD R13,32
		ADD R14,32
		ADD RDX,32
		SUB R10,1

        JMP forj1
;FINE CASO MULTIPLO--------------------------------------------------------------------------------------------------            
;CASO NON MULTIPLO-------------------------------------------------------------------------------------------------
fori1:	CMP R12,0
		JE forvexit1

		VMOVSD XMM4,[R13]   ;xast[offsetPxast+i]
		VMULSD  XMM4,XMM3	;xast[offsetPxast+i]*ris;

		VMOVSD XMM5,XMM4	;gj--->>COPIA
		VMULSD  XMM5,XMM5	;gj*gj
		VMOVSD XMM6,[RDX]	;Gj[off] vecchio
		VADDSD  XMM6,XMM5	;Gj[off] + gj*gj
		VMOVSD [RDX],XMM6	;Gj[off] nuovo

		VMULSD XMM4,XMM1	;gj = gj*eta
		VADDSD XMM6,XMM2	;sqrtrad = Gj[off]+eps
		VSQRTSD XMM6,XMM6	;radice = sqrt(sqrtrad)

		VDIVSD XMM4,XMM6	;(gj*eta/radice)
		VMOVSD XMM7,[R14]	;risultato[i] vecchio
		VADDSD XMM7,XMM4	;risultato[i]+(gj*eta/radice)
		VMOVSD [R14],XMM7	;risultato[i] nuovo
		
		ADD R13,8
		ADD R14,8
		ADD RDX,8
		SUB R12,1
		
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