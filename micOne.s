/* -- micOne.s */
/* This is a simulator that implements Tanenbaum's Mic-1. */
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
    .asciz "%d\n"

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

    @ Open the file to read 
    @ Parameters are: r0: number of params, r1: mic1, r2: filename
    @ The first argument sent in is micOne.s, so
    @ we want the next parameter
    ldr r0, [r1, #+4]!          
    
    ldr r1, =readMode
    
    @ Open the file. 
    @ This will return with a file pointer in r0
    bl fopen                    

    @ Save file pointer so we can access later
    @ Note: Don't store in r12. This isn't preserved. 
    mov r11, r0                                              
    
    @ Set up LV
    ldr mic1_LV, =memory
    
    @ Need to loop through file until you hit an EOF 
loop:
    bl fgetc
    
    @ Read bytes into "memory" 
    cmp r0, #-1
    
    @ If char equals EOF (-1), jump to end */
    beq end
    
    @ Set PC, SP, LV 
    @ Put the first character into the top of the stack and move the stack 
    @ pointer
    strb r0, [mic1_LV], #+1    

    @ Move the file pointer back to r0
    mov r0, r11                
    b loop
end:   
    @ Set the PC to the start of the stack
    ldr mic1_PC, =memory
      
    /* The LV should be in the correct position already, one byte past the PC 
       The SP should use the number of parameters and the LV to calculate its 
       position */

    @ load stack pointer with the first byte from the program and increment 
    @ the PC
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

    @ subtract one word (-4) because SP should be pointing to the last 
    @ local variable actually
    sub mic1_SP, #4
    
    @ Set CPP to 0
    mov mic1_CPP, #0

    @ Do an initial inc and fetch
    _INC_PC_FETCH_
    
Main1: 
    @ Save the MBRU (which holds the opcode) so we can cmp with it
    mov r0, mic1_MBRU

    @ Inc and fetch so we have the next byte
    _INC_PC_FETCH_

    @ Figure out which instruction to jump to
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
    @ Do nothing
    b Main1
    
iadd:
    @Read in next-to-top word on stack
    sub mic1_SP, #4
    mov mic1_MAR, mic1_SP
    _RD_

    @ H = top of stack
    mov mic1_H, mic1_TOS

    @ Add top two words; write to top of stack
    add mic1_TOS, mic1_MDR, mic1_H
    mov mic1_MDR, mic1_TOS
    _WR_

    b Main1            

isub:
    @ Read in next-to-top word on stack
    sub mic1_SP, #4
    mov mic1_MAR, mic1_SP
    _RD_

    @ H = top of stack
    mov mic1_H, mic1_TOS

    @ Do subtraction; write to TOS
    sub mic1_TOS, mic1_MDR, mic1_H
    mov mic1_MDR, mic1_TOS
    _WR_
    b Main1            

iand:
    @ Read in next-to-top word on stack
    sub mic1_SP, #4
    mov mic1_MAR, mic1_SP
    _RD_

    @ H = TOS
    mov mic1_H, mic1_TOS

    @ Do AND; write to new TOS
    and mic1_TOS, mic1_MDR, mic1_H
    mov mic1_MDR, mic1_TOS
    _WR_
    b Main1 
    
ior:
    @ Read in next-to-top word on stack
    sub mic1_SP, #4
    mov mic1_MAR, mic1_SP
    _RD_

    @ H = TOS
    mov mic1_H, mic1_TOS

    @ Do OR; write to new TOS
    orr mic1_TOS, mic1_MDR, mic1_H
    mov mic1_MDR, mic1_TOS
    _WR_
    b Main1

dup:
    @ Increment SP and copy to MAR 
    add mic1_SP, #4
    mov mic1_MAR, mic1_SP

    @ Write new stack word
    mov mic1_MDR, mic1_TOS
    _WR_
    b Main1
    
pop:
    @ Read in next-to-top word on stack
    sub mic1_SP, #4
    mov mic1_MAR, mic1_SP
    _RD_

    @ Copy new word to TOS
    mov mic1_TOS, mic1_MDR
    b Main1
    
swap:
    @ macro?
    @ Set MAR to SP - 1; read 2nd word from stack
    sub r0, mic1_SP, #4
    mov mic1_MAR, r0
    _RD_

    @ Set MAR to top word
    mov mic1_MAR, mic1_SP

    @ Save TOS in H; write 2nd word to top of stack
    mov mic1_H, mic1_MDR
    _WR_

    @ Copy old TOS to MDR
    mov mic1_MDR, mic1_TOS

    @ Set MAR to SP - 1; write as 2nd word on stack
    sub r0, mic1_SP, #4
    mov mic1_MAR, r0
    _WR_

    @ Update TOS
    mov mic1_TOS, mic1_H
    b Main1
    
bipush:
    @ MBR = the byte to push onto stack
    add mic1_SP, #4
    mov mic1_MAR, mic1_SP

    @ Sign extend constant and push onto stack
    mov mic1_TOS, mic1_MBR
    mov mic1_MDR, mic1_TOS
    _WR_

    @ Incrememnt PC, fetch next opcode
    _INC_PC_FETCH_  
    b Main1
    
iload:
    @ MBR contains index; copy LV to H
    mov mic1_H, mic1_LV
    
    @ MAR = address of local variable to push
    add mic1_MAR, mic1_H, mic1_MBRU, LSL #2
    _RD_
    
    @ SP points to new top of stack; prepare write
    add mic1_SP, #4
    mov mic1_MAR, mic1_SP

    @ Inc PC; get next opcode; write top of stack
    _INC_PC_FETCH_
    _WR_

    @ Update TOS
    mov mic1_TOS, mic1_MDR 
    b Main1
    
istore:
    @ MBR contains index; copy LV to H
    mov mic1_H, mic1_LV

    @ MAR = MBRU + H
    add mic1_MAR, mic1_H, mic1_MBRU, LSL #2

    @ Copyt TOS to MDR; write word
    mov mic1_MDR, mic1_TOS
    _WR_

    @ Read in next-to-top word on stack
    sub mic1_SP, #4
    mov mic1_MAR, mic1_SP
    _RD_

    @ Inc PC; fetch next opcode
    _INC_PC_FETCH_

    @ Update TOS
    mov mic1_TOS, mic1_MDR
    b Main1
    
iinc:
    @ MBR contains index; copy LV to H
    mov mic1_H, mic1_LV

    @ MAR = MBRU + H; read variable
    add mic1_MAR, mic1_H, mic1_MBRU, LSL #2
    _RD_

    @ Copy variable to H
    mov mic1_H, mic1_MDR

    @ Fetch constant
    _INC_PC_FETCH_

    @ Put sum in MDR; update variable
    ADD mic1_MDR, mic1_MBR, mic1_H
    _WR_

    @ Fetch next opcode
    _INC_PC_FETCH_
    b Main1
    
goto:
    @ Save address of opcode
    sub mic1_OPC, mic1_PC, #1

    @ Shift and save signed first byte in H
    mov mic1_H, mic1_MBR, LSL #8

    @ MBR = 1st byte of offset; fetch 2nd byte
    _INC_PC_FETCH_

    @ H = 16-bit branch offset
    orr mic1_H, mic1_MBRU, mic1_H

    @ Add offset to OPC
    add mic1_PC, mic1_OPC, mic1_H
    _FETCH_
    b Main1
    
iflt:
    @ Read in next-to-top word on stack
    sub mic1_SP, #4
    mov mic1_MAR, mic1_SP
    _RD_

    @ Save TOS in OPC temporarily
    movs mic1_OPC, mic1_TOS

    @ Put new top of stack in TOS
    mov mic1_TOS, mic1_MDR

    @ Branch on N bit
    bmi T
    b F
    
ifeq:
    @ Read in next-to-top word of stack
    sub mic1_SP, #4
    mov mic1_MAR, mic1_SP
    _RD_
    @ Save TOS in OPC temporarily
    movs mic1_OPC, mic1_TOS
    
    @ Put new top of stack in TOS
    mov mic1_TOS, mic1_MDR
    
    @ Branch on Z bit
    beq T
    b F
    
if_icmpeq:
    @ Read in next-to-top word of stack
    sub mic1_SP, #4
    mov mic1_MAR, mic1_SP
    _RD_

    @ Set MAR to read in new top-of-stack
    sub mic1_SP, #4
    mov mic1_MAR, mic1_SP

    @ Copy second stack word to H
    mov mic1_H, mic1_MDR
    _RD_

    @ Save TOs in OPC temporarily
    mov mic1_OPC, mic1_TOS

    @ Put new top of stack in TOS
    mov mic1_TOS, mic1_MDR
    subs r0, mic1_OPC, mic1_H

    @ If top 2 words are equal, goto T, else goto F
    beq T
    b F
    
T:
    @ Same as goto1
    b goto
    
F:
    @ Skip first offset byte
    add mic1_PC, #1

    @ PC now points to the next opcode
    _INC_PC_FETCH_
    b Main1
    
jsr:
    @ Save space for locals
    add mic1_SP, mic1_MBRU, LSL #2
    add mic1_SP, #4

    @ Push old link ptr
    mov mic1_MDR, mic1_CPP

    @ And set link pointer
    mov mic1_CPP, mic1_SP
    mov mic1_MAR, mic1_CPP
    _WR_

    @ Push return PC
    add mic1_MDR, mic1_PC, #4
    add mic1_SP, #4
    mov mic1_MAR, mic1_SP
    _WR_

    @ Push old LV
    mov mic1_MDR, mic1_LV
    add mic1_SP, #4
    mov mic1_MAR, mic1_SP
    _WR_

    @ Set new LV
    sub mic1_LV, mic1_SP, #8
    sub mic1_LV, mic1_MBRU, LSL #2

    @ Get # args
    _INC_PC_FETCH_

    @ Adjust LV to first arg
    sub mic1_LV, mic1_MBRU, LSL #2

    @ Get high byte of address
    _INC_PC_FETCH_

    @ Shift and store address
    mov mic1_H, mic1_MBR, LSL #8

    @ Get low byte of address
    _INC_PC_FETCH_

    @ Combine address and get opcode
    orr r0, mic1_H, mic1_MBRU
    sub mic1_PC, #4
    add mic1_PC, r0
    _FETCH_

    @ Transfer control
    b Main1
    
ret:
    @ Check for return from main (CPP == 0)
    cmp mic1_CPP, #0
    beq Main1End

    @ Get link ptr
    mov mic1_MAR, mic1_CPP
    _RD_

    @ Restore CPP (old link ptr)
    mov mic1_CPP, mic1_MDR

    @ Get PC
    add mic1_MAR, #4
    _RD_

    @ Restore PC and get opcode
    mov mic1_PC, mic1_MDR
    _FETCH_

    @ Get LV
    add mic1_MAR, #4
    _RD_

    @ Drop local stack 
    mov mic1_MAR, mic1_LV
    mov mic1_SP, mic1_MAR

    @ Restore LV
    mov mic1_LV, mic1_MDR

    @ Push return value 
    mov mic1_MDR, mic1_TOS
    _WR_

    @ Return control
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
