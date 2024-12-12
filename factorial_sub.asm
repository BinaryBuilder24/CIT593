;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  file name   : factorial_sub.asm                      ;
;  author      : Guljahan Yazgeldi
;  description : LC4 Assembly subroutine to compute the ;
;                factorial of a number                  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;

;; CIT 593 TO-DO:
;; 1) Open up the codio assignment where you created the factorial subroutine (in a separate browswer window)
;; 2) In that window, open up your working factorial_sub.asm file:
;;    -select everything in the file, and "copy" this content (Conrol-C) 
;; 3) Return to the current codio assignment, paste the content into this factorial_sub.asm 
;;    -now you can use the factorial_sub.asm from your last HW in this HW
;; 4) Save the updated factorial_sub.asm file

;;SUB_FACTORIAL             ; your subroutine goes here
;;   A=6 ; // 
;;   B = sub_factorial (A) ; // 
;;      
;;   regiser allocation R0=A, R1=B
.FALIGN
 SUB_FACTORIAL
  ;;prologue
  STR R7, R6, #-2 ;; save caller's return address
  STR R5, R6, #-3 ;; save caller's frame pointer
  ADD R6, R6, #-3 ;; updates stack pointer
  ADD R5, R6, #0 ;; creates/ updates frame pointer
  ADD R6, R6, #-1 ;; allocate stack space for local variables
  ;;function body
  
  LDR R0,R5,#3       ; load the arguments from the stack and copy them into R0
  CONST R1, #1       ; 
  
 ;SUB_FACTORIAL        ; factorial subroutine. ARGS: R0(A)
  CONST R1, #-1      ; sets B=-1
  CMPIU R0, #7       ; sets NZP (A-7) to ensure A>0 and A<=7. If A is neg, then it is converted to very highly positive
  BRp END_SUB        ; tests NZP to ensure A! is not larger than largest possible number as 8! causes overflow
  ADD R1, R0, #0     ; B=A
  LOOP
     CMPI R0, #1     ; sets NZP (A-1)
     BRnz END_SUB    ; tests NZP (A-1 neg or zero? If yes, goto END)
     ADD R0, R0, #-1 ; A=A-1
     MUL R1, R1, R0  ; B=B*a
  JMP LOOP           ; always goto LOOP
  END_SUB
RET
  ADD R7, R1, #0   ; storing tthe return value from R1 to the right place in the stack
  ;;epilogue
    ADD R6, R5, #0 ;; pop locals off stack
    ADD R6, R6, #3 ;; free space for return address, base pointer, and return valu
    STR R7, R6, #-1 ;; store return value
    LDR R5, R6, #-3 ;; restore base pointer
    LDR R7, R6, #-2 ;; restore return address 
RET        
