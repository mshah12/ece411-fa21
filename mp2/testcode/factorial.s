factorial.s:
 .align 4
 .section .text
 .globl factorial
 factorial:
         # Register a0 holds the input value
         # Register t0-t6 are caller-save, so you may use them without saving
         # Return value need to be put in register a0
         # Your code starts here
         add t5, a0, zero
         beq t5, zero, zero_case
         add t6, a0, zero
 factorial_loop:
         beq t5, zero, ret # if input value is zero, jump to ret
         add t3, t6, zero
         and t6, zero, zero
         addi t4, t5, -1 # else set multiplier to multiplicand - 1
 multiply:
         beq t4, zero, factorial_check # if multiplier is zero, multiplication is done and exit loop
         add t6, t3, t6 # add multiplicand to the product
         addi t4, t4, -1 # decrement multiplier
         beq t4, t4, multiply # jump to start of mutliply loop
 factorial_check:
         addi t5, t5, -1 # decrement factorial iteration value
         beq t5, t5, factorial_loop # jump to next factorial loop iteration
 zero_case: 
         addi t3, zero, 1
 ret:
         add a0, t3, zero
         jr ra # Register ra holds the return address
 .section .rodata
 # if you need any constants
 some_label:    .word 0x0000000C