/* -- micOne.s */
/* author: 1668650 */

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
stack: .skip 4096

.balign 4
stackPointer: .word stack

.balign 4
programCounter: .word stack

.balign 4
readMode:
    .asciz "r"

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
    mov r4, r0                  /* Save file pointer so we can access later */                            
    
    /* Need to loop through this until you hit an EOF */
loop:
    bl fgetc
    
    /* Read bytes into "memory" */
    cmp r0, #-1
    
    /* If char equals EOF (-1), jump to end */
    beq end
    
    /* Set PC, SP, LV */
    ldr r1, =stackPointer
    ldr r1, [r1]
    str r0, [r1]                /* Put the first character into the top of the stack */
    str r1, [r1, #+4]          /* Move the stackPointer */
    
    bl putchar
    
    mov r0, r4                  /* Move the file pointer back to r0 */
    b loop
end:   
    pop {lr}
    bx lr
    
.endfunc

/****** EXTERNAL FUNCTIONS *****/
.global fopen
.global fgetc
.global putchar
