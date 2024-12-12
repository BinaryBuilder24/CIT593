/**************************************************************
 * file name   : problem1.c                                   *
 * author      : Guljahan Yazgeldi.                           *
 * description : C program to call LC4-Assembly  TRAP_PUTC    *
 *               the TRAP is called through wrapper lc4_putc  *
 **************************************************************
*
*/

 void lc4_puts(char *str);
 int main(){
    char *msg = "I LOVE CIT 593"; //string message
    lc4_putc(msg); //calling lc4_putc
    return 0;
 }
  void lc4_puts(char *str){
    while(*str !='\0'){     // loop until Null is reached
        lc4_putc(*str);      // calling lc4_putc
        str++;               // moving to the next character
    }
  }
 

 