; Executed by the STAT interrupt handler
; We configure it to fire on each LY == IMAGE_FIRST_SCANLINE
; (i.e. one scanline before the top of the frame.)
;
; During the scanline before, the loop is prepared.
; Then we loop continuously during all the time the PPU is drawing the frame:
; 1. Preparing the palettes for the next scaline
; 2. Waiting for HBlank
; 3. Copying the palettes
; 4. Goto 1. for the next scaline
;
; The palettes copy uses a popslide to copy 4 colors quadruplets (16 colors).
STATInterrupt:
  D_LOG "STATInterrupt"

  ; Mode 2 (OAM scan), Mode 3 (Drawing) and Mode 0 (HBlank) of the scanline before the start:
  ; Use it to prepare the main loop.
  ; ------------------------------------------------------

  ; Don't do anything until the first frame is presented
  ldh a, [hFrame]
  and a
  jp z, .return

  ; Retrieve the palettes diff for the current frame
  ld hl, AnimationStruct
  call GetPresentedFrameStruct ; de = PresentedFrame
  call GetFramePalettesDiff ; hl = PresentedFrame.palettesDiff
  jp z, .return ; do nothing when there is no palettes diffs

  ; Select the palettes diffs bank
  ld a, b
  ld [rROMB0], a

  ; Save the stack pointer
  ld [hStackPointer], sp

  ; Move the stack pointer to the beginning of the palettes diffs
  ld sp, hl

  ; Request an exit of `halt` on STAT when mode 0 (HBlank)
  ld a, STATF_MODE00
  ldh [rSTAT], a
  ld a, IEF_STAT
  ldh [rIE], a
  ; (We're in an interrupt handler, so interrupts are already disabled)
  ; di

.scanlineLoop
  ; Prepare the color register (4 cycles)
  ld hl, rBGPI
  ld [hl], BGPIF_AUTOINC | 4 ; 3 cycles
  inc l ; rBGPD   ; 1 cycles

  ; Pre-pop two colors
  pop bc
  pop de

  ; Prepare the scroll register
  ; (Shift the image horizontally 4px more every 4th line)
  ldh a, [rLY]
  sub IMAGE_FIRST_SCANLINE - 1
  and a, %11111100 ; clear the two lowest bits
  sub 8 * 2 ; width of two tiles, for left black margin

  ; Wait for HBlank (STAT mode 0)
  halt
  nop ; interrupts are disabled: needs a nop instruction to avoid the `halt` bug

  ; Mode 0 - HBlank, VRAM accessible (102 GBC cycles without SCX/SCX and objects)
  ; ------------------------------------------------------

  ; Copy the two colors we stored in registers during Mode 3 (8 cycles)
  ld [hl], c  ; 2 cycles
  ld [hl], b  ; 2 cycles
  ld [hl], e  ; 2 cycles
  ld [hl], d  ; 2 cycles

  ; Fetch and copy the remaining two colors of the first quadruplet (14 cycles)
  pop de            ; 3 cycles
  ld [hl], e        ; 2 cycles
  ld [hl], d        ; 2 cycles
  pop de            ; 3 cycles
  ld [hl], e        ; 2 cycles
  ld [hl], d        ; 2 cycles

  ; Macro: copy the next quadruplet of 4 colors to a specific location (34 cycles)
MACRO copy_next_color_quadruplet_to ; index
  ; Update rBGPI to point to the correct color index
  dec l                       ; 1 cycle
  ld [hl], BGPIF_AUTOINC | \1 ; 3 cycles
  inc l                       ; 1 cycle
  ; Copy four consecutive colors
  pop de            ; 3 cycles
  ld [hl], e        ; 2 cycles
  ld [hl], d        ; 2 cycles
  pop de            ; 3 cycles
  ld [hl], e        ; 2 cycles
  ld [hl], d        ; 2 cycles
  pop de            ; 3 cycles
  ld [hl], e        ; 2 cycles
  ld [hl], d        ; 2 cycles
  pop de            ; 3 cycles
  ld [hl], e        ; 2 cycles
  ld [hl], d        ; 2 cycles
ENDM

  ; Now copy the remaining 3 quadruplets
  ; (unrolling the loop with the macro)
  copy_next_color_quadruplet_to 20
  copy_next_color_quadruplet_to 36

  ; Mode 2 - OAM scan, VRAM accessible (20 GBC cycles)
  ; ------------------------------------------------------
  copy_next_color_quadruplet_to 52

  ; Set the X scroll register (3 cycles)
  ; (This may execute one cycle after VRAM is locked - but we still can change rSCX)
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

  ; Restore the stack pointer
  ld sp, hStackPointer
  pop hl
  ld sp, hl

  ; Restore interrupts
  ld a, STATF_LYC
  ldh [rSTAT], a
  ld a, IEF_VBLANK | IEF_STAT
  ldh [rIE], a

.return
  reti
