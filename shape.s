@ Provides methods to interact with shape objects
@ Size required: 16b
@ methods:
@
@   shape_area:
@       p0 - object pointer
@       returns {low, high} 64b integer portion of shape on the top of the stack
@
@   shape:
@       p0 - object pointer
@       p1 - shape_type
@           0 - triangle
@           1 - rectangle
@           2 - trapezoid
@           3 - square
@       p2-p4 - relevant measurements
@           1: height
@           2: base (all but square) or 0
@           3: base2 (trapezoid) or 0
@       returns:
@           None
@       creates a shape object
@ 
@   
@ properties:
@   type    (obj_ptr + 0 :  word - 0, 1, 2, or 3
@   height  (obj_ptr + 4):  height of polygon
@   base    (obj_ptr + 8):  base (all but square) or zero
@   base2   (obj_ptr + 12): other base (trapezoid) or zero

.globl shape
.globl arr_labels
.globl arr_names
.globl shape_area

.include "macros.in"

.text

ptr .req r4

.type shape, %function
shape:
    setupStackNoLR

    ldr ptr, [fp,  #4]              @ Get the object pointer (arg 1)
    ldr r1,  [fp,  #8]              @ Get the object type (arg 2)
    str r1,  [ptr, #0]              @ Store object type

    ldr r1,  [fp, #12]              @ Get height (arg 3)
    str r1,  [ptr, #4]              @ Store height

    ldr r1,  [fp, #16]              @ Get base (arg 4)
    str r1,  [ptr, #8]              @ Store base

    ldr r1,  [fp,  #20]             @ Get base 2 (arg 5)
    str r1,  [ptr, #12]             @ Store base 2
    
    releaseStackNoLR #20                @ I need to release the stack and consume the pushed parameters
    mov pc, lr

@ This method sets up a single multiplication calculation
@ Two operands are generated. The specifics are below
.type shape_area, %function
shape_area:
    setupStackNoLR #12
    @ fp - 4    1st factor
    @ fp - 8    2nd factor
    @ fp - 12   Area to return

    push {ptr, r5, r6, r7, r8}      @ I need to return this the way I found it
    ldr ptr, [fp, #4]               @ Get the object pointer (arg 1)

        ldr r5, [ptr, #4]           @ All operations will use this factor
        str r5, [fp, #-4]           @ Store factor on the stack

        ldr r5, [ptr, #0]           @ Get shape type from the object
        cmp r5, #0                  
        beq area_trapezoid

        cmp r5, #1                  
        beq area_rectangle

        cmp r5, #2                  
        beq area_trapezoid

        area_square:
            @ Square
            @ factor 2 - height
            ldr r5, [ptr, #4]       @ Get height value from the object
            str r5, [fp, #-8]       @ Store value as second factor on the stack
            b area_multiply

        area_trapezoid:
            @ Triangle / Trapezoid
            @ We assume in this case that a triangle is just a trapezoid where
            @ one base is zero. 
            @ factor 2 = (base + base2)
            ldr r5, [ptr, #8]       @ Load base value from the object
            ldr r6, [ptr, #12]      @ Load base 2 value from the object (will be zero for triangle)
            add r5, r5, r6          @ Sum the two bases
            str r5, [fp, #-8]       @ Store value as second factor
            b area_multiply

        area_rectangle:
            @ Rectangle
            @ factor 2 - base
            ldr r5, [ptr, #8]       @ Load base value from the object
            str r5, [fp, #-8]       @ Store value as second factor       

        
        area_multiply:
            ldr   r5, [fp, #-4]     @ Load first factor
            ldr   r6, [fp, #-8]     @ Load second factor
            umull r7, r8, r5, r6    @ Multiply r4 and r5, store in r6 and r7
            ldr   r5, [ptr, #0]     @ Get shape type
            cmp   r5, #0            @ Need to divide by two if it's a             
            cmpne r5, #2            @   triangle or a trapezoid
            lsreq r7, r7, #1        @ Divide low by two
            orreq r7, r8, lsr #31   @ OR the low with the MSB of the high
            asreq r8, r8, #1        @ Divide high by two
            cmp   r8, #0            @ Check for overflow
            movne r7, #-1           @ If overflow, return -1
            str   r7, [fp, #-12]    @ store r6 as area

    ldr r0, [fp, #-12]              @ Get area from frame
    pop {ptr, r5, r6, r7, r8}
    releaseStackNoLR #4
    push {r0}
    mov pc, lr

.data 

@ Labels for shape lengths
.balign 4
str_height: .asciz "height"

.balign 4
str_base: .asciz "base"

.balign 4
str_base2: .asciz "opposite base"

.balign 4
arr_labels:
    .word str_height
    .word str_base
    .word str_base2

@ Shape Names
.balign 4
str_triangle: .asciz "triangle"

.balign 4
str_rectangle: .asciz "rectangle"

.balign 4
str_trapezoid: .asciz "trapezoid"

.balign 4
str_square: .asciz "square"

.balign 4
arr_names:
    .word str_triangle
    .word str_rectangle
    .word str_trapezoid
    .word str_square

