@ Lab 2 - Polygon Area
@ 
@ Author: Stephen Wight
@ Class: CS 413-01
@ Assignment: Lab 2
@
@ To assemble:
@ $ as -g -o main.o main.s
@ $ as -g -o shape.o shape.s
@ 
@ To link:
@ $ gcc -o polygon main.o shape.o
@
@ To run:
@ ./polygon
@ 
@ To debug:
@ gcc ./polygon

.globl main

.include "macros.in"
.equ READERROR, 0
.equ MENUMIN, 0
.equ MENUMAX, 4
main:
    setupStack #36
    @ fp - 16   Shape Object
    @ fp - 20   Menu Selection
    @ fp - 24   Height
    @ fp - 28   Base
    @ fp - 32   Base 2
    @ fp - 36   Shape Area

    @ base and base 2 need to be set to zero
    mov r0, #0
    str r0, [fp, #-28]
    str r0, [fp, #-32]

    start_over:
    ldr r0, =strMenu
    bl printf

    menu_prompt:
        ldr r0, =strMenuPrompt      @ Print the menu prompt  
        bl printf                   

        ldr r0, =strIntIn           @ %i filter for scanf
        sub r1, fp, #20             @ Address for menu selection on stack
        bl scanf
        cmp r0, #READERROR          @ scanf returns 0 if there was an error
            bleq clearBuffer
            beq invalid_menu
        break:
        ldr r0, [fp, #-20]          @ Load the menu selection
        cmp r0, #MENUMIN            @ Check that it is between 1 and 4
        blt invalid_menu
        cmp r0, #MENUMAX
        ble valid_menu
        invalid_menu:
            ldr r0, =strMenuError
            mov r1, #MENUMIN
            mov r2, #MENUMAX
            ldr lr, =menu_prompt
            b printf
    valid_menu:
    ldr r9, [fp, #-20]              @ r9 - type of polygon
    cmp r9, #0                      @ Check for quit condition
    beq done

    sub r9, #1                      @ Everywhere else, this is zero indexed
    str r9, [fp, #-20]

    mov r4, #2                      @ Triangle and Rectangle need two measurements

    cmp r9, #3                      @ Square (3) needs 1 measurement
    moveq r4, #1

    cmp r9, #2                      @ Trapezoid (2) needs 3 measurements
    moveq r4, #3

    mov r5, #0                      @ Loop increment and indexer
    ldr r6, =arr_names              @ Shape names
    ldr r7, =arr_labels             @ Measurement labels
    sub r8, fp, #24                 @ First position to store measurements
    meas_loop:
        ldr r0, =strValuePrompt
        ldr r1, [r7, r5, lsl #2]    @ Get the name of the measurement; index by r5 * 4
        ldr r2, [r6, r9, lsl #2]    @ Get the name of the shape; index by r9 * 4
        bl printf

        ldr r0, =strIntIn       
        sub r1, r8, r5, lsl #2      @ Address to scan to
        bl scanf

        cmp r0, #READERROR
            ldreq r0, =strNumError
            bleq printf
            ldreq lr, =meas_loop    @ I want to return to meas_loop, not here
            beq clearBuffer
        
        sub r1, r8, r5, lsl #2      @ Get address of measurement
        ldr r1, [r1]
        cmp r1, #0                  @ Check for negative values
            ldrlt r0, =strNumError
            ldrlt lr, =meas_loop    @ return to meas_loop after printing
            blt printf
        
        add r5, r5, #1              @ Increment counter
        cmp r5, r4                  @ If they're equal we've looped enough
            bne meas_loop

    @ DEFINE THE SHAPE OBJECT
    ldr r0, [fp, #-32]              @ arguments should be pushed in reverse
    ldr r1, [fp, #-28]              @    order, so here I load them into 
    ldr r2, [fp, #-24]              @    registers in reverse
    ldr r3, [fp, #-20]
    sub r4, fp, #16

    push {r0}                       @ push arguments to stack
    push {r1}
    push {r2}
    push {r3}
    push {r4}
    bl shape                        @ Call shape constructor
    
    @ GET THE SHAPE AREA
    sub r0, fp, #16                 @ Shape object address
    push {r0}                       @ Push shape object addres (only argument)
    bl shape_area                   @ Call shape_area getter
    pop {r1}                        @ Pop return value (area) from the stack
    str r1, [fp, #-36]              @ Store area on stack frame

    @ PRINT THE SHAPE AREA
    cmn r1, #1                      @ Check for -1 return
    ldreq r0, =strOverFlow
    ldrne r0, =strFinalArea
    ldr r2, [fp, #-20]              @ Get the type of shape
    ldr r1, =arr_names
    ldr r1, [r1, r2, lsl #2]        @ Get the specific name of the shape
    ldr r2, [fp, #-36]              @ Read area from stack
    bl printf

    ldr r0, =strPressEnter
    bl printf
    bl pressEnterToContinue

    b start_over

    done:
    releaseStack
    mov pc, lr

clearBuffer:                        @ lr was already set when this was called.
    ldreq r0, =strErrorIn           @ Clear buffer filter
    ldreq r1, =input_error          @ Clear buffer area in data section
    beq scanf                       @ branch, no bl. We did that manually.

pressEnterToContinue:
    mov r0, #0                      @ stdin
    ldr r1, =input_error
    mov r2, #1
    mov r7, #3
    svc #0

    mov pc, lr
.data

.balign 4
@*************
@ Instructions
@*************
strMenu:
    .ascii "Area Finder\n\n"
    .ascii "Please choose from the following options:\n"
    .ascii "0 - Quit\n"
    .ascii "1 - Triangle\n"
    .ascii "2 - Rectangle\n"
    .ascii "3 - Trapezoid\n"
    .asciz "4 - Square\n"

@********
@ Prompts
@********
.balign 4
strMenuPrompt:
    .asciz "Selection:\n"

.balign 4
strValuePrompt:
    .asciz "Enter a value for the %s of the %s:\n"

.balign 4
strPressEnter:
    .asciz "Press enter to continue...\n"

@********
@ Results
@********
.balign 4
strFinalArea:
    .asciz "The %s has an area of %u.\n"

.balign 4
strOverFlow:
    .asciz "The numbers provided caused an overflow condition.\n"

@**************
@ Input Filters
@**************
.balign 4
strIntIn: 
    .asciz " %i" 

.balign 4
strErrorIn: .asciz "%[^\n]"
@***************
@ Error Messages
@***************
.balign 4
strMenuError: 
    .asciz "You must enter a number between %d and %d.\n"

.balign 4
strNumError:
    .asciz "You must enter a positive number less than 2^32\n"

@**************
@ Input Buffers
@**************

.balign 4
input_error: .zero 100*4        @ .zero is an alias for .space, just like .skip. However, it more clearly articulates the default behavior
