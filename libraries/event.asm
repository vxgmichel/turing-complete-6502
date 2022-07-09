; Library for event management (timing and key presses) based on the timer interrupts
#once

KEYS_READOUT = 0x4200
TIMER = 0x4300

TICKS_PER_SEC = 4               ; 2 ticks per second
LATCH_VALUE = 4096 / 256        ; Latch configuration for 1 tick every 4096 cycles
SECONDS_IN_12H = 60 * 60 * 12   ; Number of seconds in 12 hours

EVENT_TICK = 0b00010000         ; Mask for 10 ms tick event
EVENT_SECOND = 0b00100000       ; Mask for 1 second event
EVENT_HALFDAY = 0b01000000      ; Mask for 1 halfday event

EVENT_LEFT = 0b00000001         ; Mask for left pressed event
EVENT_UP = 0b00000010           ; Mask for up pressed event
EVENT_RIGHT = 0b00000100        ; Mask for right pressed event
EVENT_DOWN = 0b00001000         ; Mask for down pressed event

VALUE_LEFT = 15                 ; Value for left pressed event
VALUE_UP = 16                   ; Value for up pressed event
VALUE_RIGHT = 17                ; Value for right pressed event
VALUE_DOWN = 18                 ; Value for down pressed event


; Allocate buffers and counters in RAM
#bank ram
event_ticks: #res 1             ; Count 100 ticks of 10 ms
event_seconds: #res 2           ; Count 43200 seconds (12 hours)
event_halfdays: #res 1          ; Count 256 half days (128 days)
event_flags: #res 1             ; Flags for current events


; Add functions to the program
#bank program


; Interrupt handler
event_irq:
  pha                       ; Push A onto the stack
  lda s0                    ; Load s0
  pha                       ; Push it onto the stack

  lda KEYS_READOUT          ; Check keys
  beq .tick                 ; No key events, it's a tick

  cmp #VALUE_LEFT           ; Compare with left
  bne .end_left             ; Not left
  lda event_flags           ; Keep older events
  ora #EVENT_LEFT           ; Set the tick event
  sta event_flags           ; Store in keys event
  jmp .done                 ; We're done
  .end_left:                ; Keep going

  cmp #VALUE_UP             ; Compare with up
  bne .end_up               ; Not up
  lda event_flags           ; Keep older events
  ora #EVENT_UP             ; Set the tick event
  sta event_flags           ; Store in keys event
  jmp .done                 ; We're done
  .end_up:                  ; Keep going

  cmp #VALUE_RIGHT          ; Compare with right
  bne .end_right            ; Not right
  lda event_flags           ; Keep older events
  ora #EVENT_RIGHT          ; Set the tick event
  sta event_flags           ; Store in keys event
  jmp .done                 ; We're done
  .end_right:               ; Keep going

  cmp #VALUE_DOWN           ; Compare with down
  bne .end_down             ; Not down
  lda event_flags           ; Keep older events
  ora #EVENT_DOWN           ; Set the tick event
  sta event_flags           ; Store in keys event
  jmp .done                 ; We're done
  .end_down:                ; Keep going

  jmp .done                 ; Another key event, ignore

  .tick:
  lda event_flags           ; Keep older events
  ora #EVENT_TICK           ; Set the tick event
  sta event_flags           ; Store in keys event

  inc event_ticks           ; Increment ticks counter
  lda event_ticks           ; Load ticks counter
  cmp #TICKS_PER_SEC        ; Compare with TICKS_PER_SEC
  bne .ack_timer            ; Counter is still positive, we're done

  lda #0                    ; Load zero
  sta event_ticks           ; Reset ticks counter
  inw event_seconds         ; Increment seconds counter

  lda event_flags           ; Load time events
  ora #EVENT_SECOND         ; Set the second event
  sta event_flags           ; Store time events

  lda event_seconds         ; Load lower byte of seconds counter
  cmp #SECONDS_IN_12H[7:0]  ; Compare to lower byte of 12 hours
  bne .ack_timer           ; Continue if equal
  lda event_seconds + 1     ; Load higher byte of seconds counter
  cmp #SECONDS_IN_12H[15:8] ; Countinue if equal
  bne .ack_timer            ; Continue if equal

  wrw #0 event_seconds      ; Reset seconds counter
  inc event_halfdays        ; Increment half days

  lda event_flags           ; Load time events
  ora #EVENT_HALFDAY        ; Set the halfday event
  sta event_flags           ; Store time events

  .ack_timer:
  lda TIMER                 ; Reset timer interrupt

  .done:
  pla                       ; Restore s0 from stack
  sta s0                    ; Save it
  pla                       ; Restore A register
  rts                       ; Return from subroutine


; Initialize interrupt handling
event_init:
  pha                      ; Push A onto the stack
  sei                      ; Do not allow interrupt

  wrb #0 event_ticks       ; Initialize tick counter
  wrw #0 event_seconds     ; Initialize second counter
  wrb #0 event_halfdays    ; Initialize halfday counter
  wrb #0 event_flags       ; Initialize event flags

  lda #LATCH_VALUE         ; Load latch value
  sta TIMER                ; Enable timer

  cli                      ; Allow maskable interrupts

  pla                      ; Pull A from the stack
  rts                      ; Return from subroutine


; Quit interrupt handling
event_quit:
  pha                      ; Push A onto the stack

  lda #0                   ; Load 0
  sta TIMER                ; Disable timer

  wrb #0 event_ticks       ; Reset tick counter
  wrw #0 event_seconds     ; Reset second counter
  wrb #0 event_halfdays    ; Reset halfday counter
  wrb #0 event_flags       ; Reset event flags

  pla                      ; Pull A from the stack
  rts                      ; Return from subroutine


; Sleep A times 10 ms (first tick might be less than 10 ms)
event_sleep:
  sta s0            ; Store A in s0
  .loop1:           ; Loop until s0 is zero

  lda event_ticks   ; Load ticks counter
  .loop2:           ; Wait until it changes
  cmp event_ticks   ; Compare with itself
  beq .loop2        ; Loop over if unchanged

  dec s0            ; Decrement s0
  bne .loop1        ; Loop over if s0 not zero

  rts               ; Return from subroutine


; Pop events
event_pop:
  php                ; Push processor status on the stack
  sei                ; Do not allow interrupt

  wrb event_flags s0 ; Load time events in s0
  wrb #0 event_flags ; Reset time events
  lda s0             ; Load s0

  plp                ; Restore processor status
  rts                ; Return from subroutine