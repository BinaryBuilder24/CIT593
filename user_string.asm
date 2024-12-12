;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  file name   : user_string.asm                            ;
;  author      : Guljahan Yazgeldi
;  description : read characters from the keyboard,       ;
;	             then echo them back to the ASCII display ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; The following CODE will go into USER's Program Memory
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.CODE
.ADDR x0000

;;;  Students - run this code and see how it works before modifying!
;;;  once you load it into PennSim, press "continue" instead of step to run
;;;  type a character by clicking on the white box in left hand corner of PennSim


;;;  The following code will output "Type Here>" on the ASCII display
;;;  then it will then read one character from the keyboard
;;;  and output it back to the display
;;;  HINT: you could simplify this with a directive called ".STRINGZ" - see your textbook!

	CONST R0, x54	; ASCII code for T
	TRAP x01	    ; this calls "TRAP_PUTC" in os.asm	

	CONST R0, x79   ; ASCII code for y
	TRAP x01

	CONST R0, x70   ; ASCII code for p
	TRAP x01

	CONST R0, x65   ; ASCII code for e
	TRAP x01

	CONST R0, x20   ; ASCII code for space
	TRAP x01

	CONST R0, x48	; ASCII code for H
	TRAP x01

	CONST R0, x65	; ASCII code for e
	TRAP x01

	CONST R0, x72	; ASCII code for r
	TRAP x01

	CONST R0, x65	; ASCII code for e
	TRAP x01

	CONST R0, x3E	; ASCII code for >
	TRAP x01
	
	;; To-Do
	;; add code to "loop" reading characters from keyboard and outputting them to display
	;; until the "enter" key is pressed

	;; pseudocode of algorithm you must implement for problem #1
	;;
	;; loop until (R0 == enter)
	;;    read character from keyboard into R0 using TRAP_GETC
	;;    write character from R0 to ASCII display using TRAP_PUTC
	;;    repeat loop...
	;; loop_end 
 
 .DATA
 .ADDR x4000 ; starting address
 populate_dmem
 .FILL x49 ; I
 .FILL x20 ; space
 .FILL x6C ;  l
 .FILL x6F ;  o
 .FILL x76 ;  v
 .FILL x65 ;  e 
 .FILL x20 ; space
 .FILL x43 ; C
 .FILL x49 ; I
 .FILL x54 ; T
 .FILL x20 ; space
 .FILL x35 ; 5
 .FILL x39 ; 9
 .FILL x33 ; 3
 .FILL x00 ; set the value of the last address after your string with a NULL
 .CODE
 LEA R0, populate_dmem ; load the address of the string into R0
 TRAP x03    ; calling  the TRAP_PUTS
 END ; end the program


