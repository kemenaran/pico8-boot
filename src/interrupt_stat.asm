
; Executed by the STAT interrupt handler
; We configure it to fire on each LY == 0 (i.e. the first scanline of every frame)
STATInterrupt:
  D_LOG "STATInterrupt - LYC = 0"

  ; Mode 2 - OAM scan (40 GBC cycles)
  ; Initial mode 2 of line 0: use it to prepare the main loop.
  ; ------------------------------------------------------

  ; Request an exit of `halt` on mode 0 (HBlank)
  ld a, STATF_MODE00
  ldh [rSTAT], a
  ld a, IEF_STAT
  ldh [rIE], a
  ; (We're in an interrupt handler, so interrupts are already disabled)
  ; di

.scanlineLoop
  ; Mode 3 - Drawing pixels, VRAM locked (86 cycles without SCX/SCX and objects)
  ; ------------------------------------------------------

  ; Prepare the scroll register
  ; (Shift the image horizontally 4px more every 4th line)
  ldh a, [rLY]
  sub IMAGE_FIRST_SCANLINE
  and a, %11111100 ; clear the two lowest bits
  sub 8 * 2 ; width of two tiles, for left black margin

  ; Wait for HBlank (STAT mode 0)
  halt
  ; no need for a nop, as we're pretty sure no enabled interrupt was serviced during the halt

  ; Mode 0 - HBlank, VRAM accessible (204 GBC cycles without SCX/SCX and objects)
  ; ------------------------------------------------------

  ; Set the X scroll register (3 cycles)
  ldh [rSCX], a ; 3 cycles

  ; Mode 3 - Drawing pixels, VRAM locked (86 cycles without SCX/SCX and objects)
  ; ------------------------------------------------------

  ; Manually mark the STAT Mode 0 interrupt as serviced
  ; (as IME was disabled, it wasn't done automatically by the CPU)
  ld hl, rIF         ;
  res IEB_STAT, [hl] ; 4 cycles

  ; Repeat for all scanlines
  ldh a, [rLY]
  cp IMAGE_LAST_SCANLINE - 1
  jp nz, .scanlineLoop

  ; We reached the end of the images scanlines.

  ; Restore interrupts
  ld a, STATF_LYC
  ldh [rSTAT], a
  ld a, IEF_VBLANK | IEF_STAT
  ldh [rIE], a

  reti
