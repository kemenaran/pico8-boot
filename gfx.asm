ClearBGMap0:
  ld de, _SCRN0
  ld bc, _SRAM - _SCRN0
  ld a, $FF
  jp FillData

ClearBGMap1:
  ld de, _SCRN1
  ld bc, _SRAM - _SCRN1
  ld a, $FF
  jp FillData

; Fill BG attributes map 0 with value in a
FillAttrMap0:
  push af
  ld a, 1
  ld [rVBK], a
  pop af
  ld de, _SCRN0
  ld bc, _SCRN1 - _SCRN0
  call FillData
  ld a, 0
  ld [rVBK], a
  ret

; Clear BG attributes map 1 with value in a
FillAttrMap1:
  ld a, 1
  ld [rVBK], a
  ld de, _SCRN1
  ld bc, _SRAM - _SCRN1
  ld a, %00001000
  call FillData
  xor a
  ld [rVBK], a
  ret

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
  ; Unroll the loop: copy a row in a single pass
REPT TILEMAP_WIDTH
  ld a, [de]
  ld [hli], a
  inc de
ENDR
  ; End of the tilemap row: jump to next BG row
  push de
  ld de, (SCRN_VX_B - TILEMAP_WIDTH)
  add hl, de
  pop de
  ; If not at the tilemap end yet, loop
  dec c
  jp nz, CopyTilemap
  ret
