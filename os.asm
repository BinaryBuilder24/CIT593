;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  file name   : os.asm                                 ;
;  author      : 
;  description : LC4 Assembly program to serve as an OS ;
;                TRAPS will be implemented in this file ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;


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
;;; R0 = Starting address in memory for storing keyboard input
;;; R1 = tracking the number of characters stored (excluding the null)
;;; R2 = stores status of the register
;;; R3 = points to OS_KBDR_ADDR
;;; R4 = used to validate if R0 points to a valid memory range
;;; R5 = stores the character read from the keyboard
;;; R6 = holds various values (null, ENTER and other keys)

.CODE
TRAP_GETS

 CONST R1, #0      ; initializing counter to 0
 CONST R4, x00     ; 
 HICONST R4, x20   ; storing x2000 into R4

 CMP R0, R4            ; check if R0 is less than the sarting point
 BRn DONE_GETS_NONE_WRITE ; if out of bounds, exit without writing 

 CONST R4, xFF    ;
 HICONST R4, x7F  ; storing x7FFF into R4

 CMP R0, R4                ; checking if R0 is greater than the memory limit
 BRp DONE_GETS_NONE_WRITE  ; if it does skip writing 

 CONST R4, x00 ; reset R4 to 0 for further used
 CONST R4, x00 ; reset R4 to 0 for further used

 READ 
 LC R2, OS_KBSR_ADDR     ; load the address of the keyboard status register
 LDR R2, R2, #0          ; load the contents of the status register
 BRzp READ               ; keep looping until a key is pressed

 LC R3, OS_KBDR_ADDR     ; loading the address of the keyboard data register
 LDR R5, R3, #0          ; read the character from data register
 
 CONST R6, x00 ;
 HICONST R6, x0D         ; storing the ASCII code for the ENTER key in R6
 CMP R5, R6              ; checking if ENTER was pressed
 BRz DONE_GETS           ; if ENTER was pressed, goto END
 CONST R6, x0A           ; storing the ASCII code for the Return key in R6
 CMP R5, R6              ; checking if Return was pressed
 BRz DONE_GETS           ; if Return was pressed, goto END

 CONST R6, x00 ;
 CMP R5, R6              ; checking if ENTER was pressed
 BRz DONE_GETS           ; if ENTER was pressed, goto END

 ADD R4, R0, R1          ; calculating memory location to store the current character
 STR R5, R4, #0          ; storing the character in memory at the calculated address
 ADD R1, R1, #1          ; incrementing character counter
 BRnzp READ              ; continue reading next character

 DONE_GETS
 CONST R6, x00    ;
 HICONST R6, x00  ; storing NULL terminator in R6
 
 ADD R4, R0, R1   ; calculate the memory location after the last character
 ADD R4, R4, #1   ; incrementing by one
 STR R6, R4, #0   ; storing NULL terminator

 DONE_GETS_NONE_WRITE
  RTI          ; return from TRAP

;;;;;;;;;;;;;;;;;;;;;;;;;;;   TRAP_PUTS   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Function: Put a string of characters out to ASCII display
;;; Inputs           - R0 = Address for first character
;;; Outputs          - none
;;; R0 holds the starting address of the string
;;; R1 temporarily holds the current character being read from memory
;;; R2 temporarily holds the value of the display status register
;;; R3 to store OS_ADDR_ADDR
;;; R4 holds the lower and upper bounds of valid memory ranges, which are checked
;;;    to ensure the address in R0 points to a valid memory location before proceeding

.CODE
TRAP_PUTS
 CONST R4, x00 ;
 HICONST R4 20; store x2000 into R4
 CMP R0, R4    ; comparing R0 with lower bound
 BRn DONE_PUTS ; if R0 <x4000, return without doing anything

 CONST R4, xFF ;
 HICONST R4, x7F; R4 holding the upper bounds of dmem
 CMP R0, R4     ; comparing R0 with upper bound
 BRp DONE_PUTS  ; if R0 > x7FFF, return without doing anything
 CONST R4, #0   ; initializing R4 to 0

LOAD
 ADD R2, R4, R0;
 LDR R1, R2, #0 ; R1 now holds the current character from the address in R2
 CMPI R1, x0000     ; checking if R1 holds null terminator
 BRz DONE_PUTS  ; if NULL end
 
 LC R2, OS_ADSR_ADDR ; load the address of status register
 LDR R2, R2, #0      ; load the contents into R2
 BRzp LOAD           ;  loop while ADSR[15]==1
 LC R3, OS_ADDR_ADDR ; load the address of data register
 STR R1, R3, #0      ; store the character from R1 into ADDR
 ADD R4, R4, #1      ; increment R0 to point tto the next character
 BRnzp LOAD ;
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

.CODE
TRAP_GETC_TIMER

  ;;
  ;; TO DO: complete this trap
  ;;

  RTI                  ; PC = R7 ; PSR[15]=0


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
 CONST R5, x80 ; 
 CMPU R0, R5   ; validating x coordinate
 BRzp END_DRAW ; exit if x>128
 CMPIU R1, #124; validating y coordinate
 BRzp END_DRAW ; exit if y>124

 ADD R2, R2, R0; x_end = x+width
 CMPU R3, R5   ; chechking if x is within bounds
 BRzp END_DRAW ; exit if x_end >128
 
 ADD R3, R3, R1 ; y_end = y+ length
 CMPIU R2, #124 ; same as x, chechking
 BRzp END_DRAW  ; exit if outt of bounds

 CONST R5, x00  ; 
 HICONST R5, x40; storing initial x-coordinate in memory address x4000
 STR R0, R5, #0 ;

LOOP_ROWS
 CONST R5, x00  ; reloading base memory for comparison
 HICONST R5, x40;
 CMPU R1, R3    ; 
 BRzp END_LOOP_ROWS ; exit if y > y_end

 LDR R0, R5, #0; restoring initial x coordinate for row
 LOOP_COLUMNS   ; starting innner loop
 CMPU R0, R2    ; 
 BRzp END_LOOP_COLUMNS ; exit if x>x_end

 CONST R5, #128; 
 CONST R6, x00  ; prepare memory address for drawing
 HICONST R6, xC0; set high memory bits
 MUL R5, R5, R1; calculate 128*y
 ADD R5, R5, R0; (128*y)+x
 ADD R5, R5, R6; add memory base address to pixel address
 STR R4, R5, #0; drawing with color

 ADD R0, R0, #1; incrementing x
 BRnzp LOOP_COLUMNS ; repeat inner loop

END_LOOP_COLUMNS
 ADD R1, R1, #1; incerement y
 BRnzp LOOP_ROWS; repeat outer loop

END_LOOP_ROWS
END_DRAW

 
 
  RTI


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