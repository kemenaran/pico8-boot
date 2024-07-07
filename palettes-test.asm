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
  ;jp ScanlineInterruptHardcodedSlide
  jp ScanlineInterruptHardcodedSlideRandom
  ;jp ScanlineInterruptPopSlide
  ;jp ScanlineInterruptPopSlideRandom

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
  ld hl, GrayscalePalettes
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

  ; Prepare registers for the LCDStat interrupt
  ld hl, rBGPI

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
  jr z, .disableScanlineInterrupt
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

.disableScanlineInterrupt
  ld a, IEF_VBLANK
  ldh [rIE], a

.done
  reti

; Scanline interrupt, with hardcoded color values.
; Faster than a popslide, but takes more space in ROM.
ScanlineInterruptHardcodedSlide:
  ; In theory we should save registers and restore them at the end of the interrupt,
  ; but let's see if we can get away without for now.
  ;push af
  ;push hl

  ; Mode 2 - OAM scan (40 GBC cycles)
  ; ------------------------------------------------------

  ; (ignore this mode 2, as it is for scanline 0, which we don't care about.)

  ; Mode 3 - Drawing pixels, VRAM locked (86 cycles without SCX/SCX and objects)
  ; ------------------------------------------------------

  ; Prepare the color register (4 cycles)
  ; (assuming hl has been set to rBGPI before the interrupt)
  ld [hl], BGPIF_AUTOINC | 0  ; 3 cycles
  inc l ; rBGPD               ; 1 cycles

  ; Macro: copy a color
MACRO copy_color
  ld [hl], LOW(\1)  ; 3 cycles
  ld [hl], HIGH(\1) ; 3 cycles
ENDM

  ; Wait for HBlank (mode 0)
  ld hl, rSTAT
.notHBlank
  bit STATB_BUSY, [hl]
  jr nz, .notHBlank

  ; Mode 0 - HBlank, VRAM accessible (204 GBC cycles without SCX/SCX and objects)
  ; Mode 2 - OAM scan, VRAM accessible (40 GBC cycles)
  ; Total: 244 GBC cycles
  ; ------------------------------------------------------

  ; Copy as much palettes as we can
  ld l, LOW(rBGPD) ; 2 cycles
  copy_color C_RED
  copy_color C_ORANGE
  copy_color C_DARK_BLUE
  copy_color C_BLACK

  copy_color C_ORANGE
  copy_color C_YELLOW
  copy_color C_DARK_PURPLE
  copy_color C_BLACK

  copy_color C_YELLOW
  copy_color C_GREEN
  copy_color C_DARK_GREEN
  copy_color C_BLACK

  copy_color C_GREEN
  copy_color C_BLUE
  copy_color C_BROWN
  copy_color C_BLACK

  copy_color C_BLUE
  copy_color C_LAVENDER
  copy_color C_DARK_GREY
  copy_color C_BLACK

  copy_color C_LAVENDER
  copy_color C_PINK
  copy_color C_LIGHT_GREY
  copy_color C_BLACK

  ; copy_color C_PINK
  ; copy_color C_LIGHT_PEACH
  ; copy_color C_WHITE
  ; copy_color C_BLACK
  ;
  ; copy_color C_LIGHT_PEACH
  ; copy_color C_RED
  ; copy_color C_DARK_PURPLE
  ; copy_color C_BLACK

  ; See comment above
  ;pop hl
  ;pop af
  reti ; 4 cycles

; Scanline interrupt, with hardcoded color values AND random access.
ScanlineInterruptHardcodedSlideRandom:
  ; In theory we should save registers and restore them at the end of the interrupt,
  ; but let's see if we can get away without for now.
  ;push af
  ;push hl

  ; Mode 2 - OAM scan (40 GBC cycles)
  ; ------------------------------------------------------

  ; (ignore this mode 2, as it is for scanline 0, which we don't care about.)

  ; Mode 3 - Drawing pixels, VRAM locked (86 cycles without SCX/SCX and objects)
  ; ------------------------------------------------------

  ; Prepare the color register
  ; We don't use auto-increment, as we want random access anyway
  ld de, rBGPI
  ld hl, rBGPD

  ; Wait for HBlank (mode 0)
  ld hl, rSTAT
.notHBlank
  bit STATB_BUSY, [hl]
  jr nz, .notHBlank

  ; Mode 0 - HBlank, VRAM accessible (204 GBC cycles without SCX/SCX and objects)
  ; Mode 2 - OAM scan, VRAM accessible (40 GBC cycles)
  ; Total: 244 GBC cycles
  ; ------------------------------------------------------

  ; Copy as much palettes as we can
  ld l, LOW(rBGPD) ; 2 cycles

  ; Macro: copy a pair of 2 colors to a specific location
MACRO copy_color_pair_to ; index, color1, color2
  ld a, BGPIF_AUTOINC | \1 ; 2 cycles
  ld [de], a               ; 2 cycles

  ld [hl], LOW(\2)         ; 3 cycles
  ld [hl], HIGH(\2)        ; 3 cycles
  ld [hl], LOW(\3)         ; 3 cycles
  ld [hl], HIGH(\3)        ; 3 cycles
ENDM

  copy_color_pair_to 0, C_RED, C_ORANGE
  ;copy_color_pair_to 4, C_DARK_BLUE, C_BLACK

  copy_color_pair_to 8, C_ORANGE, C_YELLOW
  ;copy_color_pair_to 12, C_DARK_PURPLE, C_BLACK

  copy_color_pair_to 16, C_YELLOW, C_GREEN
  ;copy_color_pair_to 20, C_DARK_GREEN, C_BLACK

  copy_color_pair_to 24, C_GREEN, C_BLUE
  ;copy_color_pair_to 28, C_BROWN, C_BLACK

  copy_color_pair_to 32, C_BLUE, C_LAVENDER
  ;copy_color_pair_to 36, C_DARK_GREY, C_BLACK

  copy_color_pair_to 40, C_LAVENDER, C_PINK
  ;copy_color_pair_to 44, C_LIGHT_GREY, C_BLACK

  copy_color_pair_to 48, C_PINK, C_LIGHT_PEACH
  ;copy_color_pair_to 52, C_WHITE, C_BLACK

  copy_color_pair_to 56, C_LIGHT_PEACH, C_RED
  ;copy_color_pair_to 60, C_DARK_PURPLE, C_BLACK

  ;See comment above
  ;pop hl
  ;pop af
  reti ; 4 cycles

; Popslide version of the scanline interrupt
; Slower than a hardcoded slide, but takes less space in ROM.
; TODO: maybe optimize using advices from https://forums.nesdev.org/viewtopic.php?t=17232

;
;
; di/halt will almost certainly squeeze out 1 more color. Your worst case scenario with the overhead from a busycheck is this:
; bit STATB_BUSY, [hl]
; ; change happens here
; jr nz ; taken, 3
; bit STATB_BUSY, [hl] ; 3
; jr nz ; not taken, 2
; ld l ; redundant with no dependence on hl for the wait, 2
;
; So that's 10 cycles that could be freed up from the worst case.
;
; You could also calculate/figure out the exact number of cycles to wait instead of relying on either polling or halt. This might give a 1 cycle or something advantage over halt not sure.
;
; You might also prepopulate a before waiting for HBlank. This might seem useless since 1 byte is only half a color, but maybe this will turn out to give room for one last pop de/ld [hl],e and then d might be save to seed the next prepopulated a. This is speculative though, just bouncing ideas.
;
; (The exact wait approach would still require a halt initially for synchronization.)
;
ScanlineInterruptPopSlide:
  ; Mode 2 - OAM scan (40 GBC cycles)
  ; ------------------------------------------------------

  ; (ignore this mode 2, as it is for scanline 0, which we don't care about.)

  ; Mode 3 - Drawing pixels, VRAM locked (86 cycles without SCX/SCX and objects)
  ; ------------------------------------------------------

  ; Save the stack pointer
  ld [hStackPointer], sp ; 5 cycles

  ; Move the stack pointer to the beginning of the palettes set
  ld sp, Pico8Palettes ; 3 cycles

  ; Prepare the color register (4 cycles)
  ; (assuming hl has been set to rBGPI before the interrupt)
  ld [hl], BGPIF_AUTOINC | 0 ; 3 cycles
  inc l ; rBGPD   ; 1 cycles

  ; Pre-pop two colors
  pop bc
  pop de

  ; Wait for HBlank (mode 0)
  ld hl, rSTAT
.notHBlank
  bit STATB_BUSY, [hl]
  jr nz, .notHBlank

  ; Mode 0 - HBlank, VRAM accessible (204 GBC cycles without SCX/SCX and objects)
  ; Mode 2 - OAM scan, VRAM accessible (40 GBC cycles)
  ; Total: 244 GBC cycles
  ; ------------------------------------------------------

  ld l, LOW(rBGPD) ; 2 cycles

  ; Copy the two colors we stored in registers during Mode 3 (8 cycles)
  ld [hl], c  ; 2 cycles
  ld [hl], b  ; 2 cycles
  ld [hl], e  ; 2 cycles
  ld [hl], d  ; 2 cycles

  ; Now copy as much colors as we can
REPT 20
  ; Copy a color (7 cycles)
  pop de      ; 3 cycles
  ld [hl], e  ; 2 cycles
  ld [hl], d  ; 2 cycles
ENDR

  ; Restore the stack pointer and return before the start of mode 3 (12 cycles)
  ld sp, hStackPointer  ; 3 cycles
  pop hl                ; 3 cycles
  ld sp, hl             ; 2 cycles
  reti                  ; 4 cycles

; Popslide version of the scanline interrupt, with random palette access
ScanlineInterruptPopSlideRandom:
  ; Mode 2 - OAM scan (40 GBC cycles)
  ; ------------------------------------------------------

  ; (ignore this mode 2, as it is for scanline 0, which we don't care about.)

  ; Mode 3 - Drawing pixels, VRAM locked (86 cycles without SCX/SCX and objects)
  ; ------------------------------------------------------

  ; Save the stack pointer
  ld [hStackPointer], sp ; 5 cycles

  ; Move the stack pointer to the beginning of the palettes set
  ld sp, Pico8Palettes ; 3 cycles

  ; Prepare the color register (4 cycles)
  ; (assuming hl has been set to rBGPI before the interrupt)
  ld [hl], BGPIF_AUTOINC | 0 ; 3 cycles
  inc l ; rBGPD   ; 1 cycles

  ; Pre-pop two colors
  pop bc
  pop de

  ; Wait for HBlank (mode 0)
  ld hl, rSTAT
.notHBlank
  bit STATB_BUSY, [hl]
  jr nz, .notHBlank

  ; Mode 0 - HBlank, VRAM accessible (204 GBC cycles without SCX/SCX and objects)
  ; Mode 2 - OAM scan, VRAM accessible (40 GBC cycles)
  ; Total: 244 GBC cycles
  ; ------------------------------------------------------

  ld l, LOW(rBGPD) ; 2 cycles

  ; Copy the two colors we stored in registers during Mode 3 (8 cycles)
  ld [hl], c  ; 2 cycles
  ld [hl], b  ; 2 cycles
  ld [hl], e  ; 2 cycles
  ld [hl], d  ; 2 cycles

  ; Macro: copy the next pair of 2 colors to a specific location
MACRO copy_next_color_pair_to ; index
  dec l                       ; 1 cycle
  ld [hl], BGPIF_AUTOINC | \1 ; 3 cycles
  inc l                       ; 1 cycle
  pop de
  ld [hl], e        ; 3 cycles
  ld [hl], d        ; 3 cycles
  pop de
  ld [hl], e        ; 3 cycles
  ld [hl], d        ; 3 cycles
ENDM

  ; Now copy as much colors as we can
  copy_next_color_pair_to 8
  copy_next_color_pair_to 16
  copy_next_color_pair_to 24
  copy_next_color_pair_to 32
  copy_next_color_pair_to 40
  copy_next_color_pair_to 48
  copy_next_color_pair_to 56

  ; Restore the stack pointer and return before the start of mode 3 (12 cycles)
  ld sp, hStackPointer  ; 3 cycles
  pop hl                ; 3 cycles
  ld sp, hl             ; 2 cycles
  reti                  ; 4 cycles

CopyGrayscaleTile:
  ld hl, GrayscaleTile
  ld de, _VRAM + $0FF0
  ld bc, GrayscaleTile.end - GrayscaleTile
  jp CopyData

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
