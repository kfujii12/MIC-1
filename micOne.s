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
    
    /* Set up LV */ 
    ldr mic1_LV, =stack
    
    /* Need to loop through this until you hit an EOF */
loop:
    bl fgetc
    
    /* Read bytes into "memory" */
    cmp r0, #-1
    
    /* If char equals EOF (-1), jump to end */
    beq end
    
    /* Set PC, SP, LV */
    strb r0, [mic1_LV], #+1    /* Put the first character into the top of the stack and move the stack pointer */
    mov r0, r11             /* Move the file pointer back to r0 */
    b loop
end:   
    /* Set the PC to the start of the stack */
    ldr mic1_PC, =stack
      
    /* The LV should be in the correct position already, one byte past the PC */
    /* The SP should use the number of parameters and the LV to calculate its position */
    @ load stack pointer with the first byte from the program and increment the PC
    @ Shift by 8 bits
    ldrb r12, [mic1_PC], #+1
    mov mic1_SP, r12
    LSL mic1_SP, #3
    @ Or with the next byte
    @ multiply offset by 4 (shift by 2)
    ldrb r12, [mic1_PC], #+1
    orr mic1_SP, r12
    LSL mic1_SP, #2
    @ Add to LV 
    add mic1_SP, mic1_LV
    @ subtract one word (-4) because SP should be pointing to the last local variable actually
    sub mic1_SP, #4
    
    
    _DBP_ mic1_LV
    _DBP_ mic1_PC
    _DBP_ mic1_SP

    
    pop {lr}
    bx lr
    
.endfunc

/****** EXTERNAL FUNCTIONS *****/
.global fopen
.global fgetc
.global putchar
