ClearBGMap0:
  ld a, $FF

FillBGMap0:
  ld de, _SCRN0
  ld bc, _SCRN1 - _SCRN0
  ld a, a
  jp FillData

ClearBGMap1:
  ld a, $FF

FillBGMap1:
  ld de, _SCRN1
  ld bc, _SRAM - _SCRN1
  ld a, a
  jp FillData

; Copy a tileset to VRAM, from a tileset definition in hl.
;
; The definition data format is:
;   dw <source_address>
;   db <source_bank>
;   dw <dest_address>
;   db <tiles_count>
;
; DMA is used if the LCD screen is enabled - and a regular loop otherwise.
; (In that case, the tilemap source address must be aligned to 16 bytes.)
CopyTileset:
  ld a, [rLCDC]
  and LCDCF_ON
  jp z, .noDMA

.dma
  ; Copy tileset definition to DMA registers
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
  sub 1 ; DMA transfers N+1 tiles
  ld [rHDMA5], a ; transfer starts
  ret

.noDMA
  ; hl = source
  ld a, [hli]
  ld c, a
  ld a, [hli]
  ld b, a
  push bc ; push on stack; we'll pop it back to hl before copying
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
;
; DMA can be used if and only if:
; - the tilemap is exactly 32 tiles wide,
; - the LCD screen is enabled.
; (In that case, the tilemap source address must be aligned to 16 bytes.)
; A regular unrolled loop is used otherwise.
CopyTilemap:
IF TILEMAP_WIDTH == 32
  ld a, [rLCDC]
  and LCDCF_ON
  jp nz, .dma
  ; fallthrough: use loop version
ENDC

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

.dma
  ; Copy tileset definition to DMA registers
  ; Source (high)
  ld a, d
  ld [rHDMA1], a
  ; Source (low)
  ld a, e
  ld [rHDMA2], a
  ; Dest (high)
  ; (Mask the higher bit of the destination, because DMA destination is an offset relative to $8000)
  ld a, h
  and a, %01111111
  ld [rHDMA3], a
  ; Dest (low)
  ld a, l
  ld [rHDMA4], a
  ; length, as 16-bytes chunks count
  ; (32 bytes per tilemap row, so bytes = rowsCount * 2)
  ld a, c
  add a, a ; a * 2
  sub 1 ; DMA transfers N+1 chunks
  ld [rHDMA5], a ; transfer starts
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
; Only available during V-Blank and H-Blank.
;
; The loop is unrolled. If needed, it can be further optimized using a popslide.
CopyBGPalettes:
  ld a, BCPSF_AUTOINC | 0
  ldh [rBGPI], a
REPT 64
  ld a, [hli]
  ldh [rBGPD], a
ENDR
  ret
