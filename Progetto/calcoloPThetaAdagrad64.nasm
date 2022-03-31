; ---------------------------------------------------------
; Regressione con istruzioni SSE a 32 bit
; ---------------------------------------------------------

%include "sseutils64.nasm"
section .data ;Sezione contenente dati inizializzati
;void calcoloPThetaAdagrad(type* pTheta,type* risultato,float batch,int dimTheta){
	;pTheta			equ	 	 8 RDI
	;risultato		equ		12 RSI
	;batch       	equ     16 XMM0
	;dimTheta		equ		20 RDX

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



global calcoloPThetaAdagrad

calcoloPThetaAdagrad:
		; ------------------------------------------------------------
		; Sequenza di ingresso nella funzione
		; ------------------------------------------------------------
		push		rbp							; salva il Base Pointer
		mov			rbp, rsp					; il Base Pointer punta al Record di Attivazione corrente
		pushaq									; salva i registri generali
		; ------------------------------------------------------------
		; legge i parametri dal Record di Attivazione corrente
		; ------------------------------------------------------------
			;pTheta			equ	 	 8 RDI
			;risultato		equ		12 RSI
			;batch       	equ     16 XMM0
			;dimTheta		equ		20 RDX

		VMOVSD XMM1,XMM0
		VUNPCKLPD XMM1,XMM1								;[X,X,-,-]->[X,X,X,X]
		VPERM2F128  YMM1,YMM1,YMM1,00000000 ;modificato  [X,X,-,-]->[X,X,X,X]

		MOV R8,RDX
		SHR R8,2 			;MULTIPLI
		MOV R9,R8
		SHL R9,2
		SUB RDX,R9			;NON MULTIPLI
		
		VXORPD YMM7,YMM7

;CASO MULTIPLO-----------------------------------------------------------------------------------------------------
forj:   CMP R8,0
        JE fori

		VMOVAPD YMM2,[RDI]  	   ;pTheta[i])

		VMOVAPD YMM0,[RSI]     ;risultato[i]
		VMOVAPD [RSI],YMM7	   ;risultato[i]=0	
		VDIVPD  YMM0,YMM1	   ;risultato[i]/batch; 

		
		VSUBPD YMM2,YMM0		   ;pTheta[i] - risultato[i]/batch;    
		VMOVAPD[RDI],YMM2   	   ;pTheta[i] = pTheta[i] -risultato[i]/batch;   	

		ADD RDI,32
		ADD RSI,32
		SUB R8,1

        JMP forj
;FINE CASO MULTIPLO--------------------------------------------------------------------------------------------------            
;CASO NON MULTIPLO-------------------------------------------------------------------------------------------------
fori:	CMP RDX,0
		JE forvexit

		VMOVSD XMM2,[RDI]   	   ;pTheta[i])

		VMOVSD XMM0,[RSI]   	   ;risultato[i]
		VMOVSD [RSI],XMM7	   ;risultato[i]=0	
		VDIVSD  XMM0,XMM1	   ;risultato[i]/batch; 

		VSUBSD XMM2,XMM0		   ;pTheta[i] - risultato[i]/batch;    
		VMOVSD[RDI],XMM2  	   ;pTheta[i] = pTheta[i] -risultato[i]/batch;   

		ADD RDI,8
		ADD RSI,8
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