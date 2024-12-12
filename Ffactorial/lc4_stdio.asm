;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  file name   : lc4_stdio.asm                          ;
;  author      : Guljahan Yazgeldi
;  description : LC4 Assembly subroutines that call     ;
;                call the TRAPs in os.asm (the wrappers);
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; WRAPPER SUBROUTINES FOLLOW ;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
.CODE
.ADDR x0010    ;; this code should be loaded after line 10
               ;; this is done to preserve "USER_START"
               ;; subroutine that calls "main()"


;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; TRAP_PUTC Wrapper ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.FALIGN
lc4_putc

	;; PROLOGUE ;;
        ; CIT 593 TODO: write prologue code here
	 STR R7, R6, #-2 ;; save caller's return address
         STR R5, R6, #-3 ;; save caller's frame pointer
         ADD R6, R6, #-3 ;; updates stack pointer
         ADD R5, R6, #0 ;; creates/ updates frame pointer

	;; FUNCTION BODY ;;
		; CIT 593 TODO: write code to get arguments to the trap from the stack
		;  and copy them to the register file for the TRAP call
	 LDR R0, R5, #3  ; load the arguments from the stack and copy them into R0	
	 TRAP x01        ; R0 must be set before TRAP_PUTC is called
	 
	;; EPILOGUE ;; 
		; TRAP_PUTC has no return value, so nothing to copy back to stack
	    ADD R6, R5, #0 ;; pop locals off stack
            ADD R6, R6, #3 ;; free space for return address, base pointer, and return value
            STR R7, R6, #-1 ;; store return value
            LDR R5, R6, #-3 ;; restore base pointer
            LDR R7, R6, #-2 ;; restore return address 
	    RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; TRAP_GETC Wrapper ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.FALIGN
lc4_getc

	;; PROLOGUE ;;
        ; CIT 593 TODO: write prologue code here
	 STR R7, R6, #-2 ;; save caller's return address
         STR R5, R6, #-3 ;; save caller's frame pointer
         ADD R6, R6, #-3 ;; updates stack pointer
         ADD R5, R6, #0 ;; creates/ updates frame pointer

	;; FUNCTION BODY ;;
		; CIT 593 TODO: TRAP_GETC doesn't require arguments!
		
	TRAP x00        ; Call's TRAP_GETC 
                    ; R0 will contain ascii character from keyboard
                    ; you must copy this back to the stack
	 ADD R7, R0, #0 ; storing R0 into thr R7
	;; EPILOGUE ;; 
		; TRAP_GETC has a return value, so make certain to copy it back to stack
		ADD R6, R5, #0 ;; pop locals off stack
                ADD R6, R6, #3 ;; free space for return address, base pointer, and return value
               STR R7, R6, #-1 ;; store return value
               LDR R5, R6, #-3 ;; restore base pointer
               LDR R7, R6, #-2 ;; restore return address 
               RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; TRAP_PUTS Wrapper ;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.FALIGN
lc4_puts

	;; PROLOGUE ;;
        ; CIT 593 TODO: write prologue code here
		
     STR R7, R6, #-2 ;; save caller's return address
     STR R5, R6, #-3 ;; save caller's frame pointer
     ADD R6, R6, #-3 ;; updates stack pointer
     ADD R5, R6, #0 ;; creates/ updates frame pointer
	;; FUNCTION BODY ;;
		; CIT 593 TODO: write code to get arguments to the trap from the stack
		;  and copy them to the register file for the TRAP call
	 ;LDR R0, R5, #3 ; load the address of the string into R0
	TRAP x03        ; R0 must be set before TRAP_PUTS is called
	
	;; EPILOGUE ;; 
		
        ADD R6, R5, #0 ;; pop locals off stack
        ADD R6, R6, #3 ;; free space for return address, base pointer, and return valu
        STR R7, R6, #-1 ;; store return value
        LDR R5, R6, #-3 ;; restore base pointer
        LDR R7, R6, #-2 ;; restore return address 
	RET 
