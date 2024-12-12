;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  file name   : os.asm                                 ;
;  author      : 
;  description : LC4 Assembly program to serve as an OS ;
;                TRAPS will be implemented in this file ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;

;; CIT 593 TO-DO:
;; 1) Open up your last codio assignment (in a separate browswer window)
;; 2) In that window, open up your working os.asm file:
;;    -select everything in the file, and "copy" this content (Conrol-C) 
;; 3) Return to the current codio assignment, paste the content into this os.asm 
;;    -now you can use the os.asm from your last HW in this HW
;; 4) Save the updated os.asm file
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;   OS - TRAP VECTOR TABLE   ;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.OS
.CODE
.ADDR x8000
  ; TRAP vector table
  JMP TRAP_GETC           ; x00
  JMP TRAP_PUTC           ; x01
  JMP TRAP_GETS           ; x02
  JMP TRAP_PUTS           ; x03
  JMP TRAP_TIMER          ; x04
  JMP TRAP_GETC_TIMER     ; x05
  JMP TRAP_RESET_VMEM	  ; x06
  JMP TRAP_BLT_VMEM	      ; x07
  JMP TRAP_DRAW_PIXEL     ; x08
  JMP TRAP_DRAW_RECT      ; x09
  JMP TRAP_DRAW_SPRITE    ; x0A

  ;
  ; TO DO - add additional vectors as described in homework 
  ;
  
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;   OS - MEMORY ADDRESSES & CONSTANTS   ;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;; these handy alias' will be used in the TRAPs that follow
  USER_CODE_ADDR .UCONST x0000	; start of USER code
  OS_CODE_ADDR 	 .UCONST x8000	; start of OS code

  OS_GLOBALS_ADDR .UCONST xA000	; start of OS global mem
  OS_STACK_ADDR   .UCONST xBFFF	; start of OS stack mem

  OS_KBSR_ADDR .UCONST xFE00  	; alias for keyboard status reg
  OS_KBDR_ADDR .UCONST xFE02  	; alias for keyboard data reg

  OS_ADSR_ADDR .UCONST xFE04  	; alias for display status register
  OS_ADDR_ADDR .UCONST xFE06  	; alias for display data register

  OS_TSR_ADDR .UCONST xFE08 	; alias for timer status register
  OS_TIR_ADDR .UCONST xFE0A 	; alias for timer interval register

  OS_VDCR_ADDR	.UCONST xFE0C	; video display control register
  OS_MCR_ADDR	.UCONST xFFEE	; machine control register
  OS_VIDEO_NUM_COLS .UCONST #128
  OS_VIDEO_NUM_ROWS .UCONST #124


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;; OS DATA MEMORY RESERVATIONS ;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.DATA
.ADDR xA000
OS_GLOBALS_MEM	.BLKW x1000
;;;  LFSR value used by lfsr code
LFSR .FILL 0x0001

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;; OS VIDEO MEMORY RESERVATION ;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.DATA
.ADDR xC000
OS_VIDEO_MEM .BLKW x3E00

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;   OS & TRAP IMPLEMENTATIONS BEGIN HERE   ;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.CODE
.ADDR x8200
.FALIGN
  ;; first job of OS is to return PennSim to x0000 & downgrade privledge
  CONST R7, #0   ; R7 = 0
  RTI            ; PC = R7 ; PSR[15]=0


;;;;;;;;;;;;;;;;;;;;;;;;;;;   TRAP_GETC   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Function: Get a single character from keyboard
;;; Inputs           - none
;;; Outputs          - R0 = ASCII character from ASCII keyboard

.CODE
TRAP_GETC
    LC R0, OS_KBSR_ADDR  ; R0 = address of keyboard status reg
    LDR R0, R0, #0       ; R0 = value of keyboard status reg
    BRzp TRAP_GETC       ; if R0[15]=1, data is waiting!
                             ; else, loop and check again...

    ; reaching here, means data is waiting in keyboard data reg

    LC R0, OS_KBDR_ADDR  ; R0 = address of keyboard data reg
    LDR R0, R0, #0       ; R0 = value of keyboard data reg
    RTI                  ; PC = R7 ; PSR[15]=0


;;;;;;;;;;;;;;;;;;;;;;;;;;;   TRAP_PUTC   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Function: Put a single character out to ASCII display
;;; Inputs           - R0 = ASCII character to write to ASCII display
;;; Outputs          - none

.CODE
TRAP_PUTC
  LC R1, OS_ADSR_ADDR 	; R1 = address of display status reg
  LDR R1, R1, #0    	; R1 = value of display status reg
  BRzp TRAP_PUTC    	; if R1[15]=1, display is ready to write!
		    	    ; else, loop and check again...

  ; reaching here, means console is ready to display next char

  LC R1, OS_ADDR_ADDR 	; R1 = address of display data reg
  STR R0, R1, #0    	; R1 = value of keyboard data reg (R0)
  RTI			; PC = R7 ; PSR[15]=0


;;;;;;;;;;;;;;;;;;;;;;;;;;;   TRAP_GETS   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Function: Get a string of characters from the ASCII keyboard
;;; Inputs           - R0 = Address to place characters from keyboard
;;; Outputs          - R1 = Lenght of the string without the NULL
;;; R0 = The start address of where to write keyboard input
;;; R1 = counter for how many letters were stored in memory (except the null)
;;; R2 = store status register
;;; R3 = pointer to OS_KBDR_ADDR
;;; R4 = Used to check if dmem address in R0 is out of bounds
;;; R5 = Actual value we just read from keyboard
;;; R6 = Used to store null hex, then used to store value for ENTER, and also used to store value we write to

	.CODE
 TRAP_GETS

	CONST R1, #0	 		; Initialize counter to 0

	CONST R4 x00
	HICONST R4 x20 			;; Store x2000 into R4

	CMP R0 R4	 		; CHECK if the contents of R0 are < starting point (in dmem)
	BRn DONE_GETS_NO_WRITE	 	; RTI if before starting point in dmem

	CONST R4 xFF
	HICONST R4 x7F 			;; Store x7FFF into R4

	CMP R0 R4	 		; CHECK if the contents of R0 are > ending point (in dmem)
	BRP DONE_GETS_NO_WRITE	 	; RTI if after ending point in dmem

	CONST R4 x00
	CONST R4 x00            	; Re-initiate R4 to 0 so it can be used elsewhere

 READ

	LC R2, OS_KBSR_ADDR		; load address of status register
	LDR R2, R2, #0			; load the contents of the register
	BRzp READ			; loop while ADSR[15]==0 (waiting for keyboard typing)


	LC R3, OS_KBDR_ADDR		; get the address of data register used to read from keyboard
	LDR R5, R3, #0			; read in the character at this address


	CONST R6 x00;
	HICONST R6 x0D			; Store "ENTER" hex into R6

	CMP R5 R6	 		; check if we just got the ASCII that represents the ENTER KEY BEING HIT
 	BRz DONE_GETS			; if check says we did then jump to end

	CONST R6 x0A			; Store "RETURN" hex into R6 (for my laptop?)
	CMP R5 R6	 		; check if we just got the ASCII that represents the ENTER KEY BEING HIT
 	BRz DONE_GETS			; if check says we did then jump to end


	CONST R6 x00			; Store "RETURN" hex into R6 (x00 when I run outside of )
	CMP R5 R6	 				; check if we just got the ASCII that represents the ENTER KEY BEING HIT
	BRz DONE_GETS			; if check says we did then jump to end


 	ADD R4 R0 R1			; Store in R4 where in dmem we write to on this iteration
	STR R5, R4, #0			; store ASCII value in R5 into dmem at R0


	ADD R1, R1, #1			; increment counter
	BRnzp READ


 DONE_GETS

	CONST R6 x00
	HICONST R6 x00 			; store null hex into R6


	ADD R4 R0 R1			; Get the location of the last previously written thing
	ADD R4 R4 #1			; Increment this location by one
	STR R6,R4, #0			; store null into data register located one after last place we wrote to
 DONE_GETS_NO_WRITE
	RTI						; return from TRAP and R1 should have length since it was the counter



;;;;;;;;;;;;;;;;;;;;;;;;;;;   TRAP_PUTS   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Function: Put a string of characters out to ASCII display
;;; Inputs           - R0 = Address for first character
;;; Outputs          - none
;;; R0 used to store argument from caller
;;; R1 used to load initial value
;;; R2 to see data address status register
;;; R3 to store OS_ADDR_ADDR
;;; R4 Used for comparison first and then as counter for incrementing where will store in data registers
;;; R2 = R0 + counter since LDR only takes a register and a number
;;;

	.CODE
TRAP_PUTS

	CONST R4 x00
	HICONST R4 x20 			;; Store x2000 into R4

	CMP R0 R4	 			; CHECK if the contents of R0 are < starting point (in dmem)
	BRn DONE_PUTS	 		; RTI if before starting point in dmem

	CONST R4 xFF
	HICONST R4 x7F 			;; Store x2000 into R4

	CMP R0 R4	 			; CHECK if the contents of R0 are > ending point (in dmem)
	BRp DONE_PUTS	 		; RTI if after ending point in dmem

	CONST R4, #0	 		; Initialize counter to 0

LOAD
	ADD R2, R4, R0
	LDR R1, R2, #0		 	; Load the contents of address R0 + iteration (in dmem) into R1
	CMPI R1 x0000	 		; check if we just got the ASCII that represents the end of a string
 	BRz DONE_PUTS


	LC R2, OS_ADSR_ADDR		; load address of status register
	LDR R2, R2, #0			; load the contents of the register
	BRzp LOAD				; loop while ADSR[15]==0 (not sure what we are waiting for tbh though)

	LC R3, OS_ADDR_ADDR		; get the address of data register used to display
	STR R1, R3, #0			; store ASCII value (at R5 which is OS_ADDR_ADDR + iteration we are at)

	ADD R4, R4, #1			; increment where will put the next value to

	BRnzp LOAD


DONE_PUTS
	RTI



;;;;;;;;;;;;;;;;;;;;;;;;;   TRAP_TIMER   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Function:
;;; Inputs           - R0 = time to wait in milliseconds
;;; Outputs          - none

.CODE
TRAP_TIMER
  LC R1, OS_TIR_ADDR 	; R1 = address of timer interval reg
  STR R0, R1, #0    	; Store R0 in timer interval register

COUNT
  LC R1, OS_TSR_ADDR  	; Save timer status register in R1
  LDR R1, R1, #0    	; Load the contents of TSR in R1
  BRzp COUNT    	; If R1[15]=1, timer has gone off!

  ; reaching this line means we've finished counting R0

  RTI       		; PC = R7 ; PSR[15]=0



;;;;;;;;;;;;;;;;;;;;;;;   TRAP_GETC_TIMER   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Function: Get a single character from keyboard
;;; Inputs           - R0 = time to wait
;;; Outputs          - R0 = ASCII character from keyboard (or NULL)
;;; R0 = Holds address keyboard status and then holds address
;;; R1 = Point to os timer for setting timer
;;; R2 = Holds 2000 ms in hex format
;;; R3 = Point to os timer for checking timer
;;; R4 = Store value of timer check

TRAP_GETC_TIMER

	LC R1, OS_TIR_ADDR	 ; TIR ADDRESS R1
	LC R3, OS_TSR_ADDR	 ; TSR ADDRESS R3

	CONST R2 xD0
	HICONST R2 x07       ; store 2000ms into R2
	STR R2 R1 #0		 ; set the timer

AWAIT_LOOP
	LDR R4, R3, #0		 ; R4 now has time elapsed
  ;BRn DONE_WAITING	 ; go to RTI if you're done waiting

	LC R0, OS_KBSR_ADDR
	LDR R0, R0, #0
	BRn READY_TO_READ		; jump when ready to read
	BRz AWAIT_LOOP

READY_TO_READ
	LC R0, OS_KBDR_ADDR
	LDR R0, R0, #0		; read in the character



;;;;;;;;;;;;;;;;;;;;;;;;;;;;; TRAP_RESET_VMEM ;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; In double-buffered video mode, resets the video display
;;; DO NOT MODIFY this trap, it's for future HWs
;;; Inputs - none
;;; Outputs - none
.CODE	
TRAP_RESET_VMEM
  LC R4, OS_VDCR_ADDR
  CONST R5, #1
  STR R5, R4, #0
  RTI


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; TRAP_BLT_VMEM ;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; TRAP_BLT_VMEM - In double-buffered video mode, copies the contents
;;; of video memory to the video display.
;;; DO NOT MODIFY this trap, it's for future HWs
;;; Inputs - none
;;; Outputs - none
.CODE
TRAP_BLT_VMEM
  LC R4, OS_VDCR_ADDR
  CONST R5, #2
  STR R5, R4, #0
  RTI


;;;;;;;;;;;;;;;;;;;;;;;;;   TRAP_DRAW_PIXEL   ;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Function: Draw point on video display
;;; Inputs           - R0 = row to draw on (y)
;;;                  - R1 = column to draw on (x)
;;;                  - R2 = color to draw with
;;; Outputs          - none

.CODE
TRAP_DRAW_PIXEL
  LEA R3, OS_VIDEO_MEM       ; R3=start address of video memory
  LC  R4, OS_VIDEO_NUM_COLS  ; R4=number of columns

  CMPIU R1, #0    	         ; Checks if x coord from input is > 0
  BRn END_PIXEL
  CMPIU R1, #127    	     ; Checks if x coord from input is < 127
  BRp END_PIXEL
  CMPIU R0, #0    	         ; Checks if y coord from input is > 0
  BRn END_PIXEL
  CMPIU R0, #123    	     ; Checks if y coord from input is < 123
  BRp END_PIXEL

  MUL R4, R0, R4      	     ; R4= (row * NUM_COLS)
  ADD R4, R4, R1      	     ; R4= (row * NUM_COLS) + col
  ADD R4, R4, R3      	     ; Add the offset to the start of video memory
  STR R2, R4, #0      	     ; Fill in the pixel with color from user (R2)

END_PIXEL
  RTI       		         ; PC = R7 ; PSR[15]=0
  

;;;;;;;;;;;;;;;;;;;;;;;;;;;   TRAP_DRAW_RECT   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Function: EDIT ME!
;;; Inputs    EDIT ME!
;;; Outputs   EDIT ME!

.CODE
TRAP_DRAW_RECT
;; store x start in data memory for later use
  CONST R5, x00         ; Load memory addr x4000 into R5
  HICONST R5, x40       ; Load memory addr x4000 into R5
  STR R0, R5, #0        ; Store x_start in x4000 data memory

  ; CHECK THAT INITIAL ARGUMENTS ARE VALID
  ; IF NOT, REPLACE WITH 0,0
  CMPIU R0, #0          ; Checks if R0 x coord from input is > 0
  BRn SET_ZERO          ; COORDINATE WASN'T VALID, ZERO INPUTS
  CMPIU R0, #127        ; Checks if R0 < 127
  BRp SET_ZERO          ; COORDINATE WASN'T VALID, ZERO INPUTS
  CMPIU R1, #0          ; Checks if R1 y coord from input is > 0
  BRn SET_ZERO          ; COORDINATE WASN'T VALID, ZERO INPUTS
  CMPIU R1, #123        ; Checks if R1 < 123
  BRp SET_ZERO          ; COORDINATE WASN'T VALID, ZERO INPUTS
  
  JMP SKIP_ZERO         ; WE HAD VALID COORDINATES, SO WE SKIP SETTING TO ZERO

  SET_ZERO              ; SET R0 AND R1 TO 0,0
    CONST R0, #0
    HICONST R0, #0
    CONST R1, #0
    HICONST R1, #0

  SKIP_ZERO               ; Calculate R5 and R6
    ADD R5, R0, R2        ; R5 = x_start + length
    ;; store x start in data memory for later
    CONST R6, x01         ; Load memory addr x4001 into R5
    HICONST R6, x40       ; Load memory addr x4001 into R5
    STR R5, R6, #0        ; Store x_start + LENGTH in x4001 data memory
    ADD R6, R1, R3        ; R6 = y_start + width

  ;; nested loop to draw rectangle
  ;; note, updating current x and current y in R0 and R1
  ;; note, no longer need R2 and R3, use to draw pixels
  WHILE_Y               ; while loop to iterate over x and y while drawing
    CMPIU R1, #123      ; checks if current row y > last row
    ;BRp END_DRAW
    CMPU R1, R6         ; checks if current row y > final row y
    ;BRp END_DRAW
    CMPU R0, R5         ; checks if current col x > final col x
    ;BRp SKIP_DRAW

    ;; update x to wrap around if too big
    ;; also update xfinal position in R5 to wrap around
    CMPIU R0, #127           ; checks if current x > 127
    ;BRnz DRAW_PIXEL          ; IF SO, SKIP WRAPPING X
    CONST R2, x80            ; load #-128 into R2 for subtraction
    HICONST R2, x00
    SUB R0, R0, R2           ; WRAP AROUND X
    SUB R5, R5, R2           ; WRAP AROUND FINAL X POSITION


;;;;;;;;;;;;;;;;;;;;;;;;;;;   TRAP_DRAW_SPRITE   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Function: EDIT ME!
;;; Inputs    EDIT ME!
;;; Outputs   EDIT ME!

.CODE
TRAP_DRAW_SPRITE

  ;;
  ;; TO DO: complete this trap
  ;;

  RTI


;; TO DO: Add TRAPs in HW
