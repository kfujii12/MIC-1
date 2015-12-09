/* -- micOne.s */
/* author: 1668650 */

.macro _DBP_ x
    push {r0, r1, r2, r3}
    mov r1, \x
    ldr r0, =debug_printf_format
    bl printf
    pop {r0, r1, r2, r3}
.endm

.macro _RD_
    @ Loads the information from the MAR into the MDR
    ldr mic1_MDR, [mic1_MAR]
.endm

.macro _WR_
    @ Puts address into MAR and puts it into the MDR
    str mic1_MDR, [mic1_MAR]         
.endm

.macro _INC_PC_FETCH_
    add mic1_PC, #1
    ldrsb mic1_MBR, [mic1_PC]
    ldrb mic1_MBRU, [mic1_PC]
.endm

.macro _FETCH_
    ldrsb mic1_MBR, [mic1_PC]
    ldrb mic1_MBRU, [mic1_PC]
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
    .asciz "%#X\n"

.balign 4
memory: .skip 4096

.balign 4
readMode:
    .asciz "r"
    
.balign 4
printf_format: 
    .asciz "%d\n"

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
    ldr mic1_LV, =memory
    
    /* Need to loop through this until you hit an EOF */
loop:
    bl fgetc
    
    /* Read bytes into "memory" */
    cmp r0, #-1
    
    /* If char equals EOF (-1), jump to end */
    beq end
    
    /* Set PC, SP, LV */
    strb r0, [mic1_LV], #+1    /* Put the first character into the top of the stack and move the stack pointer */
    mov r0, r11                /* Move the file pointer back to r0 */
    b loop
end:   
    /* Set the PC to the start of the stack */
    ldr mic1_PC, =memory
      
    /* The LV should be in the correct position already, one byte past the PC */
    /* The SP should use the number of parameters and the LV to calculate its position */
    @ load stack pointer with the first byte from the program and increment the PC
    @ Shift by 8 bits
    ldrb r12, [mic1_PC], #+1
    mov mic1_SP, r12
    LSL mic1_SP, #3
    @ Or with the next byte
    @ multiply offset by 4 (shift by 2)
    ldrb r12, [mic1_PC]
    orr mic1_SP, r12
    LSL mic1_SP, #2
    @ Add to LV 
    add mic1_SP, mic1_LV
    @ subtract one word (-4) because SP should be pointing to the last local variable actually
    sub mic1_SP, #4
    
    mov mic1_CPP, #0

    _INC_PC_FETCH_
    
Main1: 
    mov r0, mic1_MBRU
    _INC_PC_FETCH_
    cmp r0, #0x00
    beq nop
    cmp r0, #0x60
    beq iadd
    cmp r0, #0x64
    beq isub
    cmp r0, #0x7E
    beq iand
    cmp r0, #0x80
    beq ior
    cmp r0, #0x59
    beq dup
    cmp r0, #0x57
    beq pop
    cmp r0, #0x5F
    beq swap
    cmp r0, #0x10
    beq bipush
    cmp r0, #0x15
    beq iload
    cmp r0, #0x36
    beq istore
    cmp r0, #0x84
    beq iinc
    cmp r0, #0xA7
    beq goto
    cmp r0, #0x9B
    beq iflt
    cmp r0, #0x99
    beq ifeq
    cmp r0, #0x9F
    beq if_icmpeq
    cmp r0, #0xA8
    beq jsr
    cmp r0, #0xA9
    beq ret
    cmp r0, #0x68
    beq imul
    cmp r0, #0x6C
    beq idiv
nop:
    b Main1
    
iadd:
    sub mic1_SP, #4
    mov mic1_MAR, mic1_SP
    _RD_
    mov mic1_H, mic1_TOS
    add mic1_TOS, mic1_MDR, mic1_H
    mov mic1_MDR, mic1_TOS
    _WR_
    b Main1            

isub:
    sub mic1_SP, #4
    mov mic1_MAR, mic1_SP
    _RD_
    mov mic1_H, mic1_TOS
    sub mic1_TOS, mic1_MDR, mic1_H
    mov mic1_MDR, mic1_TOS
    _WR_
    b Main1            

iand:
    sub mic1_SP, #4
    mov mic1_MAR, mic1_SP
    _RD_
    mov mic1_H, mic1_TOS
    and mic1_TOS, mic1_MDR, mic1_H
    mov mic1_MDR, mic1_TOS
    _WR_
    b Main1 
    
ior:
    sub mic1_SP, #4
    mov mic1_MAR, mic1_SP
    _RD_
    mov mic1_H, mic1_TOS
    orr mic1_TOS, mic1_MDR, mic1_H
    mov mic1_MDR, mic1_TOS
    _WR_
    b Main1

dup:
    add mic1_SP, #4
    mov mic1_MAR, mic1_SP
    add mic1_SP, #4
    mov mic1_MAR, mic1_SP
    mov mic1_MDR, mic1_TOS
    _WR_
    b Main1
    
pop:
    sub mic1_SP, #4
    mov mic1_MAR, mic1_SP
    mov mic1_TOS, mic1_MDR
    b Main1
    
swap:
    @ macro?
    sub r0, mic1_SP, #4
    mov mic1_MAR, r0
    _RD_
    mov mic1_MAR, mic1_SP
    mov mic1_H, mic1_MDR
    _WR_
    mov mic1_MDR, mic1_TOS
    sub r0, mic1_SP, #4
    mov mic1_MAR, r0
    _WR_
    mov mic1_TOS, mic1_H
    b Main1
    
bipush:
    /* This might be broken from this first line */
    add mic1_SP, #4
    mov mic1_MAR, mic1_SP
    mov mic1_TOS, mic1_MBR
    mov mic1_MDR, mic1_TOS
    _WR_
    _INC_PC_FETCH_
    b Main1
    
iload:
    mov mic1_H, mic1_LV
    add mic1_MAR, mic1_MBRU, mic1_H
    _RD_
    add mic1_SP, #4
    mov mic1_MAR, mic1_SP
    mov mic1_TOS, mic1_MDR
    _INC_PC_FETCH_
    _WR_
    b Main1
    
istore:
    mov mic1_H, mic1_LV
    add mic1_MAR, mic1_MBRU, mic1_H
    mov mic1_MDR, mic1_TOS
    _WR_
    sub mic1_SP, #4
    mov mic1_MAR, mic1_SP
    _RD_
    mov mic1_TOS, mic1_MDR
    _INC_PC_FETCH_
    b Main1
    
iinc:
    mov mic1_H, mic1_LV
    add mic1_MAR, mic1_MBRU, mic1_H
    _RD_
    mov mic1_H, mic1_MDR
    _INC_PC_FETCH_
    ADD mic1_MDR, mic1_MBR, mic1_H
    _WR_
    _INC_PC_FETCH_
    b Main1
    
goto:
    sub mic1_OPC, mic1_PC, #-1
goto2:
    mov mic1_H, mic1_MBR, LSL #8
    _INC_PC_FETCH_
    orr mic1_H, mic1_MBRU
    add mic1_PC, mic1_OPC, mic1_H
    _FETCH_
    b Main1
    
iflt:
    sub mic1_SP, #4
    mov mic1_MAR, mic1_SP
    _RD_
    movs mic1_OPC, mic1_TOS
    mov mic1_TOS, mic1_MDR
    bmi T
    b F
    
ifeq:
    sub mic1_SP, #4
    mov mic1_MAR, mic1_SP
    _RD_
    movs mic1_OPC, mic1_TOS
    mov mic1_TOS, mic1_MDR
    bne T
    b F
    
if_icmpeq:
    sub mic1_SP, #4
    mov mic1_MAR, mic1_SP
    _RD_
    sub mic1_SP, #4
    mov mic1_MAR, mic1_SP
    mov mic1_H, mic1_MDR
    _RD_
    movs mic1_OPC, mic1_TOS
    mov mic1_TOS, mic1_MDR
    bne T
    b F
    
T:
    sub mic1_OPC, mic1_PC, #-1
    b goto2
    
F:
    add mic1_PC, #1
    _INC_PC_FETCH_
    b Main1
    
jsr:
    add mic1_SP, mic1_MBRU
    add mic1_SP, #4
    mov mic1_MDR, mic1_CPP
    mov mic1_CPP, mic1_SP
    mov mic1_MAR, mic1_CPP
    _WR_
    add mic1_MDR, mic1_PC, #4
    add mic1_SP, #4
    mov mic1_MAR, mic1_SP
    _WR_
    mov mic1_MDR, mic1_LV
    add mic1_SP, #4
    mov mic1_MAR, mic1_SP
    _WR_
    sub mic1_LV, mic1_SP, #2
    sub mic1_LV, mic1_MBRU
    _INC_PC_FETCH_
    /* Need nop? */
    sub mic1_LV, mic1_MBRU
    _INC_PC_FETCH_
    /* is this shift left 8 or 3 */
    mov mic1_H, mic1_MBR, LSL #8
    _INC_PC_FETCH_
    orr r0, mic1_H, mic1_MBRU
    sub mic1_PC, #4
    add mic1_PC, r0
    _FETCH_
    b Main1
    
ret:
    /* Check for ret from main (cpp == 0) */
    cmp mic1_CPP, #0
    beq Main1End
    mov mic1_MAR, mic1_CPP
    _RD_
    /* need nop? */
    mov mic1_CPP, mic1_MDR
    add mic1_MAR, #1
    _RD_
    /* nop? */
    mov mic1_PC, mic1_MDR
    _FETCH_
    add mic1_MAR, #1
    _RD_
    mov mic1_MAR, mic1_LV
    mov mic1_SP, mic1_MAR
    mov mic1_LV, mic1_MDR
    mov mic1_MDR, mic1_TOS
    _WR_
    b Main1

imul:
    sub mic1_SP, #4
    mov mic1_MAR, mic1_SP
    _RD_
    mov mic1_H, mic1_TOS
    mul mic1_TOS, mic1_MDR, mic1_H
    mov mic1_MDR, mic1_TOS
    _WR_
    b Main1   

idiv:
    sub mic1_SP, #4
    mov mic1_MAR, mic1_SP
    _RD_
    mov mic1_H, mic1_TOS
    mov r0, mic1_MDR
    mov r1, mic1_H
    push {r2, r3}
    bl __aeabi_uidiv
    pop {r2, r3}
    mov mic1_TOS, r0
    mov mic1_MDR, mic1_TOS
    _WR_
    b Main1

Main1End: 
    ldr r0, =printf_format
    mov r1, mic1_TOS
    bl printf
    
    pop {lr}
    bx lr

    
.endfunc

/****** EXTERNAL FUNCTIONS *****/
.global fopen
.global fgetc
.global putchar
.global printf
.global __aeabi_uidiv
