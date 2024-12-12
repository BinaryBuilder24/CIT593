/********************************************************
 * file name   : problem2.c                             *
 * author      : Thomas Farmer
 * description : C program to call LC4-Assembly TRAP_PUTC
 *               the TRAP is called through the wrapper 
 *               lc4putc() (located in lc4_stdio.asm)   *
 ********************************************************
*
*/

int main() {

	char c  ;		//declaring a variable c
  while (1){    //infinite loop
    c=lc4_getc(); //read a character from input and store in c
  if (c=='\n')
   break;     //exit the loop if Enter is pressed
  lc4_putc(c); //output character to the display
  }
	return (0) ;

}