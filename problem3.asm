;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  file name   : problem3.asm                         ;
;  author      : Guljahan Yazgeldi
;  description : LC4 Assembly subroutine: problem3    ;
;                This subroutine "calls" main()         ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;main;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		.CODE
		.FALIGN
main
	;; Prologue
	STR R7, R6, #-2        ;; save return address
	STR R5, R6, #-3        ;; save base pointer
	ADD R6, R6, #-3        ;; update stack pointer
	ADD R5, R6, #0         ;; set frame pointer (R5) to stack pointer
	ADD R6, R6, #-1        ;; allocate space for local variables

	;; Function Body
	JMP L3_problem3        ;; jump to the start of the loop

L2_problem3
	JSR lc4_getc           ;; calling lc4_getc to get a character
	LDR R7, R6, #-1        ;; grab return value (character) from the stack
	ADD R6, R6, #0         ;; free space for arguments
	STR R7, R5, #-1        ;; storing the character in the stack

	LDR R7, R5, #-1        ;; loading the character into R7
	CONST R3, #10          ;; loading the ASCII value of the Enter key (10) into R3
	CMP R7, R3             ;; comparing the character to the Enter key
	BRnp L5_problem3       ;; if it's not the Enter key, continue
	JMP L4_problem3        ;; if it's the Enter key, exit the loop

L5_problem3
	LDR R7, R5, #-1        ;; loading the character from the stack into R7
	ADD R6, R6, #-1        ;; adjusting stack pointer for storing the character
	STR R7, R6, #0         ;; storing the character in the stack
	JSR lc4_putc           ;; calling lc4_putc to output the character
	LDR R7, R6, #-1        ;; grab return value
	ADD R6, R6, #1         ;; free space for arguments

L3_problem3
	JMP L2_problem3        ;; repeat the loop

L4_problem3
	CONST R7, #0           ;; set R7 to 0 to exit

L1_problem3
	;; Epilogue
	ADD R6, R5, #0         ;; restoring stack pointer 
	ADD R6, R6, #3         ;; free space for return address, base pointer
	STR R7, R6, #-1        ;; storing return value
	LDR R5, R6, #-3        ;; restoring base pointer
	LDR R7, R6, #-2        ;; restoring return address
	RET                    ;; return to caller