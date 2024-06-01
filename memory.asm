; Copy bc bytes from hl to de
CopyData:
  ld a, [hli]
  ld [de], a
  inc de
  dec bc
  ld a, b
  or c
  jr nz, CopyData
  ret

; Fill bc bytes to de with value in a
FillData:
  push de
  pop hl
  ld d, a
.loop
  ld  a, d
  ld [hli], a
  dec bc
  ld a, b
  or c
  jr nz, .loop
  ret

; Clear bc bytes at hl with 0
ClearData:
  xor a
  ld [hli], a
  dec bc
  ld a, b
  or c
  jr nz, ClearData
  ret

; Copy c * 16 bytes from hl to de
; Destination must be in VRAM
DMAData:
  ; Mask the higher bit of the destination
  ; (because HDMA destination is an offset relative to $8000)
  ld a, $7F
  and a, d
  ld d, a
  ; Configure HDMA
  ld a, h
  ld [rHDMA1], a
  ld a, l
  ld [rHDMA2], a
  ld a, d
  ld [rHDMA3], a
  ld a, e
  ld [rHDMA4], a
  ld a, c
  ld [rHDMA5], a ; transfer starts
  ret

; Copy c tiles from hl to de
; de must be in VRAM
;
; HDMA is used if the LCD screen is enabled (regular loop otherwise)
CopyTiles:
  ld a, [rLCDC]
  and LCDCF_ON
  jp z, .noDMA
.dma
  jp DMAData
.noDMA
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
