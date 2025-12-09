    extrn code(init_LCD,LCD_XY,zapisz_string_LCD)

    org 8000h
    jmp start
    org 8500h

start:
    lcall init_LCD

    mov A, #00000000b
    lcall LCD_XY
    mov DPTR, #imie
    lcall zapisz_string_LCD

    mov A, #01000000b
    lcall LCD_XY
    mov DPTR, #nazwisko
    lcall zapisz_string_LCD
    jmp $

imie:
    DB 'bajo#'

nazwisko:
    DB 'jajo#'
	
    end

