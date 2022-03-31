; ---------------------------------------------------------
; Regressione con istruzioni SSE a 32 bit
; ---------------------------------------------------------

%include "sseutils32.nasm"


section .data			; Sezione contenente dati inizializzati
;void ripristinaVetZero(int v[], int scarto,int grado)
	v			equ	 	 8
	scarto		equ		12
	grado		equ		16
		

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



global ripristinaVetZero

ripristinaVetZero:
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
	  	;for(i = grado-gCorr;i< grado;i++){
      	; v[i] = 0;
   		;}
		MOV EAX,[EBP+v]
		XOR EBX,EBX 				;x=0
        MOV EDI,[EBP+grado]			;GRADO

		MOV ESI,[EBP+scarto] 	


fori:	CMP EDI,ESI
		JE forvexit

		MOV[EAX+ESI*4],EBX	
		ADD ESI,1

		JMP fori          
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