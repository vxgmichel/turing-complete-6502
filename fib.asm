; Debug program

#include "layouts/eater.asm"

#bank ram
string_buffer: #res 32

#bank program

; Main program

reset:
  cli
  ldx #0xff             ; Initialize the stack pointer at the end of its dedicated page
  txs

  jsr lcd_init          ; Initialize LCD display
  wrw #0x0000 r0        ; Load 0 in word r0
  wrw #0x0001 r2        ; Load 1 in word r2

  .main:                ; Main program

  wrw r2 a0             ; Copy value in word r0 to first argument
  wrw #string_buffer a2 ; Load string buffer as destination
  jsr to_base10         ; Convert to decimal

  wrw #string_buffer a0 ; Copy string buffer address to a0
  jsr lcd_print_str     ; Print string buffer to LCD
  lda #" "              ; Load a separator
  jsr lcd_print_char    ; Print the separator


  wrw r2 s0             ; Write r2 to s0
  lda r0                ; Load r0
  clc                   ; Clear carry
  adc r2                ; Add r2 lower byte
  sta r2                ; Write to r2 lower byte
  lda r1                ; Load r0 higher byte
  adc r3                ; Add r2 higher byte
  sta r3                ; Write to r2 higer byte
  wrw s0 r0             ; Write older r2 to r0

  jmp .main             ; Loop over


; Interrupt handling

nmi:
  rti

irq:
  rti

; Libraries

#include "libraries/lcd.asm"
#include "libraries/util.asm"
#include "libraries/decimal.asm"