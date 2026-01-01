; Monitor Firmware is placed in the beginning of the program address space (from 0000h to 1FFFh)
; so the actual user's program must be placed at the address 8000h.
; The program below actually starts at the address 8500h because lower memory region
; is also used by the interrupt vectors.

    ; display.LIB code starts from adress 9800h and uses 40h-4ah memory region of RAM
    EXTRN code(init_LCD,LCD_XY,zapisz_string_LCD,dispACC_LCD)

    ORG 8000h
    jmp main
    ORG 8500h

    num1_lo   EQU 20h
    num1_hi   EQU 21h
    num2_lo   EQU 22h
    num2_hi   EQU 23h
    result_lo EQU 24h
    result_hi EQU 25h

num1:
    DB 0FFh, 0FFh
num2:
    DB 02h, 00h

main:
    lcall init_LCD

    lcall add16

    mov A, #0
    lcall LCD_XY
    mov DPTR, #label
    lcall zapisz_string_LCD

    mov A, #10
    lcall LCD_XY
    mov A, R4
    lcall dispACC_LCD
    mov A, #12
    lcall LCD_XY
    mov A, R5
    lcall dispACC_LCD

    mov R0, #80h
    mov R1, #80h
    lcall shiftleft16

    jmp $

label:
    DB 'wynik:#'

;-----------------------------------------
; add 16-bit values
; (R5:R4) + C = (R2:R0) + (R3:R1)
;-----------------------------------------
add16:
    ; mov low byte of num1 into R0
    mov A, #0
    mov DPTR, #num1
    movc A, @A+DPTR
    mov R0, A

    ; mov low byte of num2 into R1
    mov A, #0
    mov DPTR, #num2
    movc A, @A+DPTR
    mov R1, A

    ; mov high byte of num1 into R2
    mov A, #0
    mov DPTR, #num1+1
    movc A, @A+DPTR
    mov R2, A

    ; mov high byte of num2 into R3
    mov A, #0
    mov DPTR, #num2+1
    movc A, @A+DPTR
    mov R3, A

    ; add low bytes and store in R4
    mov A, R0
    add A, R1
    mov R4, A

    ; add high bytes with carry and store in R5
    mov A, R2
    addc A, R3
    mov R5, A

    ret

;-----------------------------------------
; shift left 16-bit value
; (R1:R0) = (R1:R0) << 1
;-----------------------------------------
shiftleft16:
    clr C ; clear carry flag so it is not rotated into the bit0 of lsb
    mov A, R0
    rlc A
    mov R0, A

    mov A, R1
    rlc A
    mov R1, A

    ret

END
