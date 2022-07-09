; Library for controlling the LCD
#once


; LCD constants

LCD_BASE = 0x4100
CURSOR_CHAR = 219


; LCD globals
#bank ram
lcd_cursor: #res 1
lcd_blink_state: #res 1
lcd_blink_enable: #res 1
lcd_current_char: #res 1

; LCD functions

#bank program

lcd_init:
  lda #0                   ; Load 0
  sta lcd_cursor           ; Reset cursor
  sta lcd_blink_enable     ; Reset blinking
  sta lcd_blink_state      ; Reset blink state
  sta lcd_current_char     ; Reset current char
  rts                      ; Return from subroutine

lcd_print_num:
  sta s0              ; Save argument in s0
  txa                 ; Transfer X to A
  pha                 ; Push X onto the stack
  lda r0              ; Load r0
  pha                 ; And push onto the stack
  lda s0              ; Restore argument in s0
  sta r0              ; And store to r0
  lsr a               ; Shift 4 times
  lsr a               ; to keep the 4 higher bits
  lsr a               ; ...
  lsr a               ; ...
  tax                 ; Transfer A to X
  lda hexa_symbols, x ; Load hexa value corresponding to X
  jsr lcd_print_char  ; Call print_char
  lda r0              ; Restore original argument
  and #0b00001111     ; Keep lower 4 bits
  tax                 ; Transfer A to X
  lda hexa_symbols, x ; Load hexa value corresponding to X
  jsr lcd_print_char  ; Call print_char
  lda r0              ; Load r0
  sta s0              ; And store to s0
  pla                 ; Pull r0 from the stack
  sta r0              ; And restore
  pla                 ; Pull original X from stack
  tax                 ; Restore original X
  lda s0              ; Restore argument in s0
  rts                 ; Return from subroutine


hexa_symbols:
#d "0123456789abcdef"



; Print the character in the accumulator to the LCD display
lcd_print_char:
  sta s0                ; Save argument to s0
  txa                   ; Push X
  pha                   ; onto the stack

  ldx lcd_cursor        ; Load cursor to X
  lda s0                ; Load argument
  sta LCD_BASE, x       ; Write current character

  inx                   ; Increment X
  txa                   ; Copy to A
  sta lcd_cursor        ; Move cursor
  lda LCD_BASE, x       ; Read current character
  sta lcd_current_char  ; Save current character

  pla                   ; Restore X
  tax                   ; From the stack
  rts                   ; Return from subroutine


; Clear display and return home
lcd_clear:
  pha                   ; Save A
  txa                   ; Push X
  pha                   ; Onto the stack

  lda lcd_cursor        ; Load cursor
  tax                   ; to X
  lda #0                ; Load 0

  .clear_loop:
  cpx #0                ; Compare X with zero
  beq .end_clear_loop   ; Break if cursor is zero
  dex                   ; Decrement X
  sta LCD_BASE, x       ; Clear X position
  jmp .clear_loop       ; Loop over
  .end_clear_loop:

  lda #0                ; Load position 0
  jsr lcd_seek          ; Return home

  ; TODO: clear
  pla                   ; Restore X
  tax                   ; From the stack
  pla                   ; Restore A
  rts                   ; Return from subroutine


; Print the string with address in a0 to LCD
lcd_print_str:
  tya                   ; Transfer Y to A
  pha                   ; And push it onto the stack

  ldy #0                ; Initalize Y register
  .char_loop:           ; Loop over characters

  lda (a0), y           ; Get a character from message, indexed by Y
  beq .done             ; Done with the printing
  jsr lcd_print_char    ; Print the character
  iny                   ; Increment Y
  jmp .char_loop        ; Loop over

  .done:                ; Done with the printing
  pla                   ; Pull Y from the stack
  tay                   ; And transfer it
  rts                   ; Return


; Move cursor to position
lcd_seek:
  sta s0                ; Save argument to s0
  txa                   ; Push X
  pha                   ; onto the stack

  ldx lcd_cursor        ; Load cursor to X
  lda lcd_current_char  ; Load current char to A
  sta LCD_BASE, x       ; Write current char (to erase blinking)

  lda s0                ; Load argument
  sta lcd_cursor        ; Move cursor
  tax                   ; Copy cursor to X
  lda LCD_BASE, x       ; Read current character
  sta lcd_current_char  ; Save current character

  pla                   ; Restore X
  tax                   ; From the stack
  rts                   ; Return from subroutine


; Return the cursor postion
lcd_tell:
  lda lcd_cursor
  rts                 ; Return from subroutine

; Move cursor left
lcd_move_left:
  pha
  lda lcd_cursor
  sec
  sbc #1
  jsr lcd_seek
  pla
  rts                 ; Return from subroutine


; Move cursor right
lcd_move_right:
  pha
  lda lcd_cursor
  clc
  adc #1
  jsr lcd_seek
  pla
  rts                 ; Return from subroutine


; Enable blinking
lcd_blink_on:
  pha
  lda #0
  sta lcd_blink_state
  lda #1
  sta lcd_blink_enable
  pla
  rts


; Enable blinking
lcd_blink_off:
  pha
  lda #0
  sta lcd_blink_state
  sta lcd_blink_enable
  pla
  rts


; Tick blinking
lcd_blink_tick:
  sta s0                ; Save argument to s0
  txa                   ; Push X
  pha                   ; onto the stack

  lda lcd_blink_enable  ; Test blink enable
  beq .done             ; We're done

  ldx lcd_cursor        ; Load cursor to X

  lda lcd_blink_state   ; Test blink state
  bne .state1           ; Go to state 1

  .state0:
  lda lcd_current_char  ; Load current char to A
  jmp .write            ; Go to write
  .state1:
  lda #CURSOR_CHAR      ; Load cursor char

  .write:
  sta LCD_BASE, x       ; Write current char or cursor char
  lda lcd_blink_state   ; Load blink state
  eor #0b00000001       ; Toggle state
  sta lcd_blink_state   ; Write back

  .done:
  pla                   ; Restore X
  tax                   ; From the stack
  rts                   ; Return from subroutine


; Delete a character from the LCD display
lcd_del_char:
  ; TODO
  rts                 ; Return from subroutine


; Go to next line on the LCD
lcd_new_line:
  ; TODO
  rts
