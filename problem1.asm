;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  file name   : problem1.asm                         ;
;  author      : Guljahan Yazgeldi
;  description : LC4 Assembly subroutine: problem1    ;
;                This subroutine "calls" main()         ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;main;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		.CODE
		.FALIGN
main
	;; prologue
	STR R7, R6, #-2	;; save return address
	STR R5, R6, #-3	;; save base pointer
	ADD R6, R6, #-3 ;; adjusting stack
	ADD R5, R6, #0  ;; set frame pointer
	ADD R6, R6, #-2	;; allocate space for local variables
	;; function body
	CONST R7, #5    ;; A = 5
	STR R7, R5, #-1
	CONST R7, #0   ;; b= 0
	STR R7, R5, #-2
	LDR R7, R5, #-1;; loading value of a into R7
	ADD R6, R6, #-1;; allocate space for argument
	STR R7, R6, #0 ;; storing a as an argument for SUB_FACTORIAL
	JSR SUB_FACTORIAL
	LDR R7, R6, #-1	;; grab return value
	ADD R6, R6, #1	;; free space for arguments
	STR R7, R5, #-2 ;; storing result in 'b'
	CONST R7, #0    ;; return value of main
L1_problem1
	;; epilogue
	ADD R6, R5, #0	;; pop locals off stack
	ADD R6, R6, #3	;; free space for return address, base pointer, and return value
	STR R7, R6, #-1	;; store return value
	LDR R5, R6, #-3	;; restore base pointer
	LDR R7, R6, #-2	;; restore return address
	RET
