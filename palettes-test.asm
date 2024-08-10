; A test ROM, to see how many palettes colors we can replace during a single HBlank.
;
; It loads a repeated stripped tile and a grayscale palette – and 0.5s
; after enables an HBlank interrupt for 1 frame, which will try to push
; as many different colors as possible during one scanline.
;
; To compile: make palettes-test.gbc

INCLUDE "hardware.inc"
INCLUDE "pico8.inc"
INCLUDE "constants.asm"

DEF TILEMAP_WIDTH  = 20
DEF TILEMAP_HEIGHT = 18
DEF TILEMAP_TOP    = 0
DEF TILEMAP_LEFT   = 0

DEF PALETTE_SWAP_START_VI EQU 30
DEF INTERRUPT_LOOP_FIRST_SCANLINE EQU 7
DEF INTERRUPT_LOOP_LAST_SCANLINE EQU 136

SECTION "Interrupt VBlank", ROM0[$0040]
  jp VBlankInterrupt

SECTION "LCD Status interrupt", ROM0[$0048]
  jp ScanlineInterruptPopSlideRandom

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

  ; Load tileset
  ld hl, Frame4TilesetDef
  call CopyTileset

  ; Load tilemap
  ld de, Frame4Tilemap ; source
  ld hl, _SCRN0        ; destination
  ld c, TILEMAP_HEIGHT ; rows count
  call CopyTilemap

  ; Load attributes map
  ld de, Frame4Attrmap  ; source
  ld hl, _SCRN0         ; destination
  ld bc, ATTRMAP_HEIGHT ; rows count
  call CopyAttrmap

  ; Load a grayscale BG palettes set
  ld hl, GrayscalePalettes
  call CopyBGPalettes

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
  jr nz, .done

.enableScanlineInterrupt
  ; Trigger the scanline interrupt on LYC == INTERRUPT_LOOP_FIRST_SCANLINE
  ld a, STATF_LYC
  ldh [rSTAT], a
  ld a, INTERRUPT_LOOP_FIRST_SCANLINE
  ldh [rLYC], a
  ; Enable the scanline interrupt
  ld a, IEF_VBLANK | IEF_STAT
  ldh [rIE], a

  ; Load the palette for scanline 0
  ld hl, InitialPalettesSet
  call CopyBGPalettes

.done
  reti

; Popslide version of the scanline interrupt, with random palette access.
; Can copy up to 8 color pairs (16 colors) with random access per scanline (Mode 0 + Mode 2)
ScanlineInterruptPopSlideRandom:
  ; Mode 2 - OAM scan (40 GBC cycles)
  ; Initial mode 2 of line 0: use it to prepare the main loop.
  ; ------------------------------------------------------

  ; Save the stack pointer
  ld [hStackPointer], sp ; 5 cycles

  ; Move the stack pointer to the beginning of the palettes set diffs
  ld sp, PalettesDiffForScanline._0 ; 3 cycles

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

  ; Prepare the color register (4 cycles)
  ld hl, rBGPI
  ld [hl], BGPIF_AUTOINC | 0 ; 3 cycles
  inc l ; rBGPD   ; 1 cycles

  ; Pre-pop two colors
  pop bc
  pop de

  ; Prepare the scroll register
  ; (We shift the image horizontally 1px on every scanline)
  ;
  ; TODO: implement the actual pico8 animation shift (0-1-2-1-0-1-2-1-0)
  ldh a, [rLY]
  sub INTERRUPT_LOOP_FIRST_SCANLINE

  ; Wait for HBlank (STAT mode 0)
  halt
  ; no need for a nop, as we're pretty sure no enabled interrupt was serviced during the halt

  ; Mode 0 - HBlank, VRAM accessible (204 GBC cycles without SCX/SCX and objects)
  ; ------------------------------------------------------

  ; Copy the two colors we stored in registers during Mode 3 (8 cycles)
  ld [hl], c  ; 2 cycles
  ld [hl], b  ; 2 cycles
  ld [hl], e  ; 2 cycles
  ld [hl], d  ; 2 cycles

  ; Macro: copy the next pair of 2 colors to a specific location (19 cycles)
MACRO copy_next_color_pair_to ; index
  ; Update rBGPI to point to the correct color index
  dec l                       ; 1 cycle
  ld [hl], BGPIF_AUTOINC | \1 ; 3 cycles
  inc l                       ; 1 cycle
  ; Copy two consecutive colors
  pop de            ; 3 cycles
  ld [hl], e        ; 2 cycles
  ld [hl], d        ; 2 cycles
  pop de            ; 3 cycles
  ld [hl], e        ; 2 cycles
  ld [hl], d        ; 2 cycles
ENDM

  ; Now copy as much colors as we can
  ; (unrolling the loop with a macro)
  copy_next_color_pair_to 8
  copy_next_color_pair_to 16
  copy_next_color_pair_to 24
  copy_next_color_pair_to 32
  copy_next_color_pair_to 40

  ; Mode 2 - OAM scan, VRAM accessible (40 GBC cycles)
  ; ------------------------------------------------------

  copy_next_color_pair_to 48
  copy_next_color_pair_to 56

  ; Set the X scroll register (3 cycles)
  ; (This may execute one cycle after VRAM is locked - but even though we still can change rSCX)
  ldh [rSCX], a ; 3 cycles

  ; Mode 3 - Drawing pixels, VRAM locked (86 cycles without SCX/SCX and objects)
  ; ------------------------------------------------------

  ; Manually mark the STAT Mode 0 interrupt as serviced
  ; (as IME was disabled, it wasn't done automatically by the CPU)
  ld hl, rIF         ;
  res IEB_STAT, [hl] ; 4 cycles

  ; Repeat for all scanlines
  ldh a, [rLY]
  cp INTERRUPT_LOOP_LAST_SCANLINE - 1
  jp nz, .scanlineLoop

  ; We reached the end of scanlines, and entered the VBlank period.

  ; Restore the stack pointer (8 cycles)
  ld sp, hStackPointer  ; 3 cycles
  pop hl                ; 3 cycles
  ld sp, hl             ; 2 cycles

  ; Restore interrupts (5 cycles)
  ld a, IEF_VBLANK | IEF_STAT ; 2 cycles
  ldh [rIE], a          ; 3 cycles

  ; Return (4 cycles)
  reti                  ; 4 cycles

INCLUDE "memory.asm"
INCLUDE "gfx.asm"

; -------------------------------------------------------------------------------
SECTION "Graphics", ROMX, BANK[$01]

Frame4Tileset:
INCBIN "gfx/4.indexed.tileset.2bpp"
  .end

Frame4TilesetDef:
  dw Frame4Tileset ; source address
  db BANK(Frame4Tileset) ; source bank
  dw _VRAM ; dest address
  db ((Frame4Tileset.end - Frame4Tileset) / 16) ; tiles_count

Frame4Tilemap:
INCBIN "gfx/4.indexed.tilemap"
  .end

ALIGN 4
Frame4Attrmap:
; First row
REPT 20
  db $00
ENDR
; Colored rows
REPT 16
  db $00, $00, $00, $01, $02, $03, $04, $05, $06, $07, $00, $01, $02, $03, $04, $05, $06, $07, $00, $00
ENDR
; Last row
REPT 20
  db $00
ENDR

INCLUDE "gfx/4.indexed.palettes.asm"

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
