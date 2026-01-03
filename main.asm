; Monitor Firmware is placed in the beginning of the program address space (from 0000h to 1FFFh)
; so the actual user's program must be placed at the address 8000h.
; The program below actually starts at the address 8500h because lower memory region
; is also used by the interrupt vectors.

    ; display.LIB code starts from adress 9800h and uses 40h-4ah memory region of RAM
    EXTRN code(init_LCD,LCD_XY,zapisz_string_LCD,dispACC_LCD)

    ORG 8000h
    jmp main
    ORG 8500h

    ; variables to use in montgomery multiplication
    a_lo        EQU 20h
    a_hi        EQU 21h
    b_lo        EQU 22h
    b_hi        EQU 23h
    m_lo        EQU 24h
    m_hi        EQU 25h
    result_lo   EQU 26h
    result_hi   EQU 27h

    ; variable to use in cmp_ge16 subroutine
    cmp_var     EQU 28h

main:
    lcall   init_LCD

    mov     A, R4
    lcall   dispACC_LCD

    mov     m_lo, #01h
    mov     m_hi, #00h
    lcall   montgomery_mul16

    mov     R0, #01h
    mov     R1, #81h
    lcall   shiftright16

    jmp     $

;-----------------------------------------
; add 16-bit values
; A + B = C
; in:   R1:R0 = a_hi:a_lo
;       R3:R2 = b_hi:b_lo
; out:  R5:R4 = c_hi:c_lo + Carry flag
;-----------------------------------------
add16:
    ; add low bytes and store in R4
    mov     A, R0
    add     A, R2
    mov     R4, A

    ; add high bytes with carry and store in R5
    mov     A, R1
    addc    A, R3
    mov     R5, A

    ret

;-----------------------------------------
; subtract 16-bit values
; A - B = C
; in:   R1:R0 = a_hi:a_lo
;       R3:R2 = b_hi:b_lo
; out:  R5:R4 = c_hi:c_lo + Carry (borrow) flag
;-----------------------------------------
sub16:
    clr     C
    mov     A, R0
    subb    A, R2
    mov     R4, A

    mov     A, R1
    subb    A, R3
    mov     R5, A

    ret

    subb    A, R2
    mov     R4, A

    ret

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

;-----------------------------------------
; shift right 16-bit value
; in:   R1:R0 = a_hi:a_lo
; out:  R1:R0 = (a_hi:a_lo) >> 1
;-----------------------------------------
; important note:
; if needed, carry flag must explicitly cleared before shifting operation
;-----------------------------------------
shiftright16:
    mov     A, R1
    rrc     A
    mov     R1, A

    mov     A, R0
    rrc     A
    mov     R0, A

    ret

; ---------------------------------------------------------
; uint16 montgomery_mul(uint16 A, uint16 B, uint16 M)
; in:   A_lo:A_hi }
;       B_lo:B_hi } RAM addresses
;       M_lo:M_hi }
; out:  result_lo:result_hi = (A * B * R⁻¹ mod M) in Montgomery's representation
; ---------------------------------------------------------
montgomery_mul16:
    ; initialize result with 0
    mov     result_lo, #0
    mov     result_hi, #0

    ; get bit count of modulus into R7
    lcall   get_bit_cnt16
    mov     R7, A

    mont_loop:

    ; if (A & 1) result += B
    ; -----------------------
    mov     A, a_lo
    anl     A, #01h
    jz      skip_add_b
    ; result += B

    skip_add_b:

    ; if (result & 1) result += M
    ; ----------------------------
    mov     A, result_lo
    anl     A, #01h
    jz      skip_add_m

    ;result += M

    skip_add_m:

    ; result >>= 1
    ; -------------

    ; A >>= 1
    ; --------

    djnz    R7, mont_loop

    ; if result >= M then result -= M
    ; -------------------------------
    mov     R0, result_lo
    mov     R1, result_hi
    mov     R2, m_lo
    mov     R3, m_hi
    lcall   cmp16_ge
    jz      montgomery_mul16_done

    lcall   sub16 ; final result in in R5:R4
    mov     result_lo, R4
    mov     result_hi, R5

    montgomery_mul16_done:
    ret

; ---------------------------------------------------------
; cmp16_ge
; in:   R1:R0 = a_hi:a_lo
;       R3:R2 = b_hi:b_lo
; out:  A = 1 if a >= b, 0 if a < b
; ---------------------------------------------------------
cmp16_ge:
    push    0
    push    1
    push    2
    push    3

    ; compare high bytes
    mov     A, R1
    mov     cmp_var, R3
    cjne    A, cmp_var, check_hi_diff
    ; compare low bytes
    mov     A, R0
    mov     cmp_var, R2
    cjne    A, cmp_var, check_lo_diff
    ; if both bytes are equal
    mov     A, #1
    ljmp    cmp16_ge_done

    check_hi_diff:
    jc      a_less ; if carry flag is set, second operand is greater
    mov     A, #1
    ljmp    cmp16_ge_done

    check_lo_diff:
    jc      a_less ; if carry flag is set, second operand is greater
    mov     A, #1
    ljmp    cmp16_ge_done

    a_less:
    mov     A, #0

    cmp16_ge_done:
    pop     3
    pop     2
    pop     1
    pop     0

    ret
    
; ---------------------------------------------------------
; get_bit_cnt16
; in:   m_lo, m_hi
; out:  A = number of bits (MSB index + 1)
; ---------------------------------------------------------
get_bit_cnt16:
    push 7

    ; set initial bit count value to 0
    mov     R7, #0
    mov     A, m_lo
    orl     A, m_hi
    jz      get_bit_cnt16_done ; return if all bytes are zeros

    ; check if m_hi != 0
    mov     A, m_hi
    jnz     msb_in_hi

    msb_in_lo:
    mov     R7, #9 ; max bit count is 8
    mov     A, m_lo

    find_msb_lo:
    dec     R7
    clr     C
    rlc     A
    jnc     find_msb_lo ; until bit7 == 0

    ljmp    get_bit_cnt16_done

    msb_in_hi:
    mov     R7, #17 ; max bit count is 16
    mov     A, m_hi

    find_msb_hi:
    dec     R7
    clr     C
    rlc     A
    jnc     find_msb_hi

    get_bit_cnt16_done:
    mov     A, R7
    pop     7
    ret

END
