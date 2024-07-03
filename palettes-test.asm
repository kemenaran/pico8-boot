; A test ROM, to see how many palettes colors we can replace during a single HBlank.
;
; It loads a repeated stripped tile and a grayscale palette – and 0.5s
; after enables an HBlank interrupt for 1 frame, which will try to push
; as many different colors as possible during one scanline.
;
; To compile: make palettes-test.gbc

INCLUDE "hardware.inc"
INCLUDE "constants.asm"

DEF PALETTE_SWAP_START_VI EQU 30

SECTION "Interrupt VBlank", ROM0[$0040]
  jp VBlankInterrupt

SECTION "LCD Status interrupt", ROM0[$0048]
  jp ScanlineInterruptPopSlide
  ;jp ScanlineInterruptHardcodedSlide

SECTION "Header", ROM0[$100]
  jp EntryPoint

ds $150 - @, 0 ; Make room for the header

EntryPoint:
  ; Shut down audio circuitry
  ld a, 0
  ld [rNR52], a

  ; Turn the LCD off
  ; (do not turn the LCD off outside of VBlank)
.waitVBlank
  ld a, [rLY]
  cp 144
  jr c, .waitVBlank
  ld a, 0
  ld [rLCDC], a

  ; Switch CPU to double-speed
  xor  a
  ldh  [rIE], a
  ld   a, P1F_5 | P1F_4
  ldh  [rP1], a
  ld   a, KEY1F_PREPARE
  ldh  [rKEY1], a
  stop

  ; Initialize stack
  ld sp, wStackTop

  ; Clear HRAM
  ld hl, _HRAM
  ld bc, $FFFE - _HRAM
  call ClearData

  ; Clear BG maps
  call ClearBGMap0
  call ClearBGMap1

  ; Load attributes map
  ld de, Attrmap ; source
  ld hl, _SCRN0  ; destination
  ld bc, 18      ; rows count
  call CopyAttrmap

  ; Load a grayscale BG palettes set
  ld hl, DMGPalettes
  call CopyBGPalettes

  ; Load a single grayscale tile
  call CopyGrayscaleTile

  ; Turn the LCD on
  ld a, LCDCF_ON | LCDCF_BGON | LCDCF_BLK01 | LCDCF_WINOFF | LCDCF_OBJOFF
  ld [rLCDC], a

  ; During the first (blank) frame, initialize display registers
  ld a, %11100100
  ld [rBGP], a

  ; Configure interrupts
  di
  ld a, IEF_VBLANK
  ldh [rIE], a
  ei

  ; Start the main loop
  jp MainLoop

MainLoop:
  ; Stop the CPU until the next interrupt
  halt
  nop
  ; Ensure we actually reached v-blank
.ensureVBlank
  ld a, [rLY]
  cp 144
  jr c, .ensureVBlank

  ; Loop
  jp MainLoop

; Executed by the VBlank interrupt handler
VBlankInterrupt:
  ; Increment the VI count
  ld hl, hVICount
  inc [hl]

  ; If we reached the demo start, enable the palette swap code
  ld a, [hVICount]
  cp PALETTE_SWAP_START_VI
  jr z, .enableScanlineInterrupt
  ; One frame after, disable the palette swap code
  cp PALETTE_SWAP_START_VI + 1
  jr z, .disableAllInterrupt
  jp .done

.enableScanlineInterrupt
  ; Trigger the scanline interrupt on LYC == 1
  ld a, STATF_LYC
  ldh [rSTAT], a
  ld a, 1
  ldh [rLYC], a
  ; Enable the scanline interrupt
  ld a, IEF_VBLANK | IEF_STAT
  ldh [rIE], a
  jr .done

.disableAllInterrupt
  xor 0
  ldh [rIE], a

.done
  reti

; Scanline interrupt with hardcoded color values
ScanlineInterruptHardcodedSlide:
  ; In theory we should save registers and restore them at the end of the interrupt,
  ; but let's see if we can get away without for now.
  ;push af
  ;push hl

  ; Prepare the color register
  ld a, BCPSF_AUTOINC | 0
  ldh [rBGPI], a

  ; Copy a color (8 cycles)
MACRO copy_color
  ld a, HIGH(\1) ; 2 cycles
  ld [hl], a     ; 2 cycles
  ld a, LOW(\1)  ; 2 cycles
  ld [hl], a     ; 2 cycles
ENDM

  ; Copy as much palettes as we can
  ld hl, rBGPD   ; 3 cycles
REPT 4
  copy_color $F75B
  copy_color $E50F
  copy_color $8102
  copy_color $8001
ENDR

  ; See comment above
  ;pop hl
  ;pop af
  reti

; Popslide version of the scanline interrupt
ScanlineInterruptPopSlide:
  ; Mode 2 - OAM scan (40 GBC cycles)
  ; ------------------------------------------------------

  ; (called the interrupt handler - 5 cycles)

  ; Save the stack pointer
  ld [hStackPointer], sp ; 5 cycles

  ; Move the stack pointer to the beginning of the palettes set
  ld sp, GreenPalettes ; 3 cycles

  ; Prepare the color register (7 cycles)
  ld a, BCPSF_AUTOINC | 0 ; 2 cycles
  ldh [rBGPI], a          ; 3 cycles
  ld l, LOW(rBGPD)        ; 2 cycles

  ; Push some bytes before the end of Mode 2
REPT 2
  ; Copy a color (7 cycles)
  pop de      ; 3 cycles
  ld [hl], e  ; 2 cycles
  ld [hl], d  ; 2 cycles
ENDR

  ; Mode 3 - Drawing pixels, VRAM locked (86 cycles)
  ; ------------------------------------------------------

  ; Pre-pop two colors
  pop bc
  pop de

  ; Wait for HBlank (mode 0)
  ld hl, rSTAT
.notHBlank
  bit STATB_BUSY, [hl]
  jr nz, .notHBlank

  ; Mode 0 - HBlank, VRAM accessible (204 GBC cycles)
  ; ------------------------------------------------------

  ld l, LOW(rBGPD) ; 2 cycles

  ; Copy the two colors we stored in registers during Mode 3 (8 cycles)
  ld [hl], c  ; 2 cycles
  ld [hl], b  ; 2 cycles
  ld [hl], e  ; 2 cycles
  ld [hl], d  ; 2 cycles

  ; Now copy as much colors as we can
REPT 12
  ; Copy a color (7 cycles)
  pop de      ; 3 cycles
  ld [hl], e  ; 2 cycles
  ld [hl], d  ; 2 cycles
ENDR

  ; Restore the stack pointer and return (12 cycles)
  ld sp, hStackPointer  ; 3 cycles
  pop hl                ; 3 cycles
  ld sp, hl             ; 2 cycles
  reti                  ; 4 cycles

CopyGrayscaleTile:
  ld hl, GrayscaleTile
  ld de, _VRAM + $0FF0
  ld bc, GrayscaleTile.end - GrayscaleTile
  jp CopyData

GreenPalettes:
  dw $F75B, $E50F, $8102, $8001
  dw $F75B, $E50F, $8102, $8001
  dw $F75B, $E50F, $8102, $8001
  dw $F75B, $E50F, $8102, $8001
  dw $F75B, $E50F, $8102, $8001
  dw $F75B, $E50F, $8102, $8001
  dw $F75B, $E50F, $8102, $8001
  dw $F75B, $E50F, $8102, $8001

INCLUDE "memory.asm"
INCLUDE "gfx.asm"

; -------------------------------------------------------------------------------
SECTION "Tilesets - frame 1-4", ROMX, BANK[$01]

ALIGN 4 ; Align to 16-bytes boundaries, for HDMA transfer
GrayscaleTile:
INCBIN "gfx/grayscale.2bpp"
  .end

Attrmap:
  db $00, $00, $01, $01, $02, $02, $03, $03, $04, $04, $05, $05, $06, $06, $07, $07, $07, $07, $07, $07
  db $00, $00, $01, $01, $02, $02, $03, $03, $04, $04, $05, $05, $06, $06, $07, $07, $07, $07, $07, $07
  db $00, $00, $01, $01, $02, $02, $03, $03, $04, $04, $05, $05, $06, $06, $07, $07, $07, $07, $07, $07
  db $00, $00, $01, $01, $02, $02, $03, $03, $04, $04, $05, $05, $06, $06, $07, $07, $07, $07, $07, $07
  db $00, $00, $01, $01, $02, $02, $03, $03, $04, $04, $05, $05, $06, $06, $07, $07, $07, $07, $07, $07
  db $00, $00, $01, $01, $02, $02, $03, $03, $04, $04, $05, $05, $06, $06, $07, $07, $07, $07, $07, $07
  db $00, $00, $01, $01, $02, $02, $03, $03, $04, $04, $05, $05, $06, $06, $07, $07, $07, $07, $07, $07
  db $00, $00, $01, $01, $02, $02, $03, $03, $04, $04, $05, $05, $06, $06, $07, $07, $07, $07, $07, $07
  db $00, $00, $01, $01, $02, $02, $03, $03, $04, $04, $05, $05, $06, $06, $07, $07, $07, $07, $07, $07
  db $00, $00, $01, $01, $02, $02, $03, $03, $04, $04, $05, $05, $06, $06, $07, $07, $07, $07, $07, $07
  db $00, $00, $01, $01, $02, $02, $03, $03, $04, $04, $05, $05, $06, $06, $07, $07, $07, $07, $07, $07
  db $00, $00, $01, $01, $02, $02, $03, $03, $04, $04, $05, $05, $06, $06, $07, $07, $07, $07, $07, $07
  db $00, $00, $01, $01, $02, $02, $03, $03, $04, $04, $05, $05, $06, $06, $07, $07, $07, $07, $07, $07
  db $00, $00, $01, $01, $02, $02, $03, $03, $04, $04, $05, $05, $06, $06, $07, $07, $07, $07, $07, $07
  db $00, $00, $01, $01, $02, $02, $03, $03, $04, $04, $05, $05, $06, $06, $07, $07, $07, $07, $07, $07
  db $00, $00, $01, $01, $02, $02, $03, $03, $04, $04, $05, $05, $06, $06, $07, $07, $07, $07, $07, $07
  db $00, $00, $01, $01, $02, $02, $03, $03, $04, $04, $05, $05, $06, $06, $07, $07, $07, $07, $07, $07
  db $00, $00, $01, $01, $02, $02, $03, $03, $04, $04, $05, $05, $06, $06, $07, $07, $07, $07, $07, $07
  .end

; -------------------------------------------------------------------------------
SECTION "WRAM Stack", WRAM0[$CE00]

; Bottom of WRAM is used as the stack
wStack::
  ds $CFFF - @ + 1

; Init puts the SP here
DEF wStackTop EQU $CFFF

; -------------------------------------------------------------------------------
SECTION "HRAM", HRAM[$FF80]

; Number of vertical interrupts that occured
hVICount: ds 1

; Original address of the stack pointer
hStackPointer: ds 2
