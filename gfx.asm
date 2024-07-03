ClearBGMap0:
  ld de, _SCRN0
  ld bc, _SCRN1 - _SCRN0
  ld a, $FF
  jp FillData

ClearBGMap1:
  ld de, _SCRN1
  ld bc, _SRAM - _SCRN1
  ld a, $FF
  jp FillData

; Copy a tileset to VRAM, from a tileset definition in hl.
;
; The definition data format is:
;   dw <source_address>
;   dw <source_bank>
;   dw <dest_address>
;   ds <tiles_count>
;
; HDMA is used if the LCD screen is enabled (regular loop otherwise)
CopyTileset:
  ld a, [rLCDC]
  and LCDCF_ON
  jp z, .noDMA

.dma
  ; Copy tileset definition to HDMA registers
  ; Source (low)
  ld a, [hli]
  ld [rHDMA2], a
  ; Source (high)
  ld a, [hli]
  ld [rHDMA1], a
  ; Source bank
  ld a, [hli]
  ld [rROMB0], a
  ; Dest (low)
  ld a, [hli]
  ld [rHDMA4], a
  ; Dest (high)
  ; (Mask the higher bit of the destination, because HDMA destination is an offset relative to $8000)
  ld a, [hli]
  and a, $7F
  ld [rHDMA3], a
  ; Tiles count
  ld a, [hl]
  sub 1 ; HDMA transfers N+1 tiles
  ld [rHDMA5], a ; transfer starts
  ret

.noDMA
  ; hl = source
  ld a, [hli]
  ld c, a
  ld a, [hli]
  ld b, a
  push bc ; push on stack; we'll pop it back to hl befre copying
  ; source bank
  ld a, [hli]
  ld [rROMB0], a
  ; de = destination
  ld a, [hli]
  ld e, a
  ld a, [hli]
  ld d, a
  ; c = tiles count
  ld a, [hl]
  ld c, a
  ; bc = c * 16
  ld b, c
  sla c
  sla c
  sla c
  sla c
  srl b
  srl b
  srl b
  srl b
  pop hl ; restore source address to hl
  jp CopyData

; Copy a tilemap of c rows from de to hl (a rectangular region of VRAM)
CopyTilemap:
.loop
  ; Unroll the loop: copy a row in a single pass
REPT TILEMAP_WIDTH
  ld a, [de]
  ld [hli], a
  inc de
ENDR
  ; End of the row: jump to next BG row
  push de
  ld de, (SCRN_VX_B - TILEMAP_WIDTH)
  add hl, de
  pop de
  ; If not at the end yet, loop
  dec c
  jp nz, .loop
  ret

; Copy an attributes map of c rows from de to hl (a rectangular region of VRAM)
CopyAttrmap:
  ld a, 1
  ld [rVBK], a
.loop
  ; Unroll the loop: copy a row in a single pass
REPT ATTRMAP_WIDTH
  ld a, [de]
  ld [hli], a
  inc de
ENDR
  ; End of the row: jump to next BG row
  push de
  ld de, (SCRN_VX_B - ATTRMAP_WIDTH)
  add hl, de
  pop de
  ; If not at the end yet, loop
  dec c
  jp nz, .loop
  ; Restore VRAM bank
  xor a
  ld [rVBK], a
  ret

; Pico8 colors
DEF C_BLACK       EQU $0000 ; #000000
DEF C_DARK_BLUE   EQU $28A3 ; #1D2B53
DEF C_DARK_PURPLE EQU $288F ; #7E2553
DEF C_DARK_GREEN  EQU $2A00 ; #008751
DEF C_BROWN       EQU $1955 ; #ab5236
DEF C_DARK_GREY   EQU $254B ; #5F574F
DEF C_LIGHT_GREY  EQU $6318 ; #C2C3C7
DEF C_WHITE       EQU $77DF ; #FFF1E8
DEF C_RED         EQU $241F ; #FF004D
DEF C_ORANGE      EQU $029F ; #FFA300
DEF C_YELLOW      EQU $139F ; #FFEC27
DEF C_GREEN       EQU $1B80 ; #00E436
DEF C_BLUE        EQU $7EA5 ; #29ADFF
DEF C_LAVENDER    EQU $4DD0 ; #83769C
DEF C_PINK        EQU $55DF ; #FF77A8
DEF C_LIGHT_PEACH EQU $573F ; #FFCCAA

; Fully black palettes
BlackPalettes:
  dw $0000, $0000, $0000, $0000
  dw $0000, $0000, $0000, $0000
  dw $0000, $0000, $0000, $0000
  dw $0000, $0000, $0000, $0000
  dw $0000, $0000, $0000, $0000
  dw $0000, $0000, $0000, $0000
  dw $0000, $0000, $0000, $0000
  dw $0000, $0000, $0000, $0000

; 8 identical DMG-like palettes
GrayscalePalettes:
  dw $7FFF, $5EF7, $3DEF, $0000
  dw $7FFF, $5EF7, $3DEF, $0000
  dw $7FFF, $5EF7, $3DEF, $0000
  dw $7FFF, $5EF7, $3DEF, $0000
  dw $7FFF, $5EF7, $3DEF, $0000
  dw $7FFF, $5EF7, $3DEF, $0000
  dw $7FFF, $5EF7, $3DEF, $0000
  dw $7FFF, $5EF7, $3DEF, $0000

; A pico8-like set of 8 palettes
Pico8Palettes:
  dw C_RED, C_ORANGE, C_DARK_BLUE, C_BLACK
  dw C_ORANGE, C_YELLOW, C_DARK_PURPLE, C_BLACK
  dw C_YELLOW, C_GREEN, C_DARK_GREEN, C_BLACK
  dw C_GREEN, C_BLUE, C_BROWN, C_BLACK
  dw C_BLUE, C_LAVENDER, C_DARK_GREY, C_BLACK
  dw C_LAVENDER, C_PINK, C_LIGHT_GREY, C_BLACK
  dw C_PINK, C_LIGHT_PEACH, C_WHITE, C_BLACK
  dw C_LIGHT_PEACH, C_RED, C_DARK_PURPLE, C_BLACK

; Writes $40 bytes located at HL to the BG palettes.
; Only available during V-Blank.
CopyBGPalettes:
  ld a, BCPSF_AUTOINC | 0
  ldh [rBGPI], a
  ld b, 64
.loop
  ld a, [hli]
  ldh [rBGPD], a
  dec b
  jr nz, .loop
  ret
