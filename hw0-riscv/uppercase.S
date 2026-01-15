        .section .data
input_string:   .asciz "Hello world!"

        # tohost/fromhost are data locations used by Spike
        .align 8
tohost: .byte 0
        .align 8
fromhost: .byte 0

        
        .section .text
        .globl _start
_start:
        # Load the address of the input string into a0
        la a0, input_string

        # Your code here!
        mv t0, a0

loop: 
        lbu t1, 0(t0)
        beqz t1, end_program
        li t2, 97
        blt t1, t2, next_char

        li t2, 122
        blt t2, t1, next_char
        addi t1, t1, -32
        sb t1, 0(t0)

next_char:
        addi t0, t0, 1
        j loop
        
end_program:
        # jump here when you're done
        j end_program

