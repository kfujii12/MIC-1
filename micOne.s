/* -- micOne.s */
/* author: 1668650 */

.macro _DBP_ x
    push {r0, r1, r2, r3}
    mov r1, \x
    ldr r0, =debug_printf_format
    bl printf
    pop {r0, r1, r2, r3}
.endm

/***** NAMING REGISTERS *****/
mic1_MAR .req r2 
mic1_MDR .req r3
mic1_PC .req r4
mic1_MBR .req r5
mic1_MBRU .req r6
mic1_SP .req r7
mic1_LV .req r8
mic1_CPP .req r9
mic1_TOS .req r10
mic1_OPC .req r11
mic1_H .req r12

.data

.balign 4
debug_printf_format:
    .asciz "%d\n"

.balign 4
stack: .skip 4096

.balign 4
readMode:
    .asciz "r"
    
.balign 4
printf_format: 
    .asciz "%#x\n"

.text

.global main
.func main
main: 
    push {lr}

    /* Open the file to read */
    /* Parameters are: r0: number of params, r1: mic1, r2: filename */
    ldr r0, [r1, #+4]!          /* The first argument sent in is micOne.s, so */
                                /* we want the next parameter */
    
    ldr r1, =readMode
    
    bl fopen                    /* Open the file. This will return with a */
                                /* file pointer in r0 */
    mov r11, r0                  /* Save file pointer so we can access later */                            
    
    /* Set up SP */ 
    ldr mic1_SP, =stack
    
    /* Need to loop through this until you hit an EOF */
loop:
    bl fgetc
    
    /* Read bytes into "memory" */
    cmp r0, #-1
    
    /* If char equals EOF (-1), jump to end */
    beq end
    
    /* Set PC, SP, LV */
    strb r0, [mic1_SP], #+1    /* Put the first character into the top of the stack and move the stack pointer */
    mov r0, r11             /* Move the file pointer back to r0 */
    b loop
end:   
    ldr mic1_PC, =stack
    
    pop {lr}
    bx lr
    
.endfunc

/****** EXTERNAL FUNCTIONS *****/
.global fopen
.global fgetc
.global putchar
