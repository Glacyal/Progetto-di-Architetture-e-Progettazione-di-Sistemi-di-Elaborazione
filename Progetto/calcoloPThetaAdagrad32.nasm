; ---------------------------------------------------------
; Regressione con istruzioni SSE a 32 bit
; ---------------------------------------------------------

%include "sseutils32.nasm"
section .data ;Sezione contenente dati inizializzati
;void calcoloPThetaAdagrad(type* pTheta,type* risultato,float batch,int dimTheta){
	pTheta			equ	 	 8
	risultato		equ		12
	batch       	equ     16
	dimTheta		equ		20

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
		push		ebp							; salva il Base Pointer
		mov			ebp, esp					; il Base Pointer punta al Record di Attivazione corrente
		push		ebx							; salva i registri da preservare
		push		esi
		push		edi
		; ------------------------------------------------------------
		; legge i parametri dal Record di Attivazione corrente
		; ------------------------------------------------------------
		MOV EAX,[EBP+pTheta]    ;BASE VETTORE pTheta
		MOV EBX,[EBP+risultato]	;BASE VETTORE risultato
		MOV ESI,[EBP+dimTheta]	;DIMENSIONE TOTALE

		MOVSS XMM1,[EBP+batch]
		SHUFPS XMM1,XMM1,00000000b


		MOV EDI,ESI
		SHR EDI,2 			;MULTIPLI
		MOV ECX,EDI
		SHL ECX,2
		SUB ESI,ECX			;NON MULTIPLI
		
		XORPS XMM7,XMM7

;CASO MULTIPLO-----------------------------------------------------------------------------------------------------
forj:   CMP EDI,0
        JE fori

		MOVAPS XMM2,[EAX]  	   ;pTheta[i])

		MOVAPS XMM0,[EBX]  	   ;risultato[i]
		MOVAPS [EBX],XMM7	   ;risultato[i]=0	
		DIVPS  XMM0,XMM1	   ;risultato[i]/batch; 

		
		SUBPS XMM2,XMM0		   ;pTheta[i] - risultato[i]/batch;    
		MOVAPS[EAX],XMM2   	   ;pTheta[i] = pTheta[i] -risultato[i]/batch;   	

		ADD EAX,16
		ADD EBX,16
		SUB EDI,1

        JMP forj
;FINE CASO MULTIPLO--------------------------------------------------------------------------------------------------            
;CASO NON MULTIPLO-------------------------------------------------------------------------------------------------
fori:	CMP ESI,0
		JE forvexit

		MOVSS XMM2,[EAX]   	   ;pTheta[i])

		MOVSS XMM0,[EBX]   	   ;risultato[i]
		MOVSS [EBX],XMM7	   ;risultato[i]=0	
		DIVSS  XMM0,XMM1	   ;risultato[i]/batch; 

		SUBSS XMM2,XMM0		   ;pTheta[i] - risultato[i]/batch;    
		MOVSS[EAX],XMM2  	   ;pTheta[i] = pTheta[i] -risultato[i]/batch;   

		ADD EAX,4
		ADD EBX,4
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