;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  file name   : problem4.asm                         ;
;  author      : Guljahan Yazgeldi
;  description : LC4 Assembly subroutine: problem4    ;
;                         ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;;;;;;;;;;;;;;;;;;;;;;;;;;;;main;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		.CODE
		.FALIGN
lc4_puts
	;; prologue
	STR R7, R6, #-2	;; save return address
	STR R5, R6, #-3	;; save base pointer
	ADD R6, R6, #-3 ;; adjusting stack pointer
	ADD R5, R6, #0  ;; set frame pointer
	;; function body
    LDR R1, R5, #2 ;; loading the address of the string
    ;ADD R6, R6, #-1;; allocate space for the character
 PRINT_LOOP
    LDR R0, R1, #0 ;; loading current character
    BRz END_PRINT        ;; if character is null exit
    JSR lc4_putc   ;; output character
    ADD R1, R1, #1 ;; move to the next character
    BRnzp PRINT_LOOP;;
 END_PRINT
    ADD R6, R6, #1 ;; free space    
   
	;; epilogue
	ADD R6, R5, #0	;; pop locals off stack
	ADD R6, R6, #3	;; free space for return address, base pointer, and return value
    STR R7, R6, #-1 ;; store return value
	LDR R5, R6, #-3	;; restore base pointer
	LDR R7, R6, #-2	;; restore return address
	RET

