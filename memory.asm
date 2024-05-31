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

; Fill bc bytes of the BG map with value in a
FillBGMap:
  ld   d, a
  ld hl, _SCRN0
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

; Fill HRAM with 0
ClearHRAM:
  ld hl, _HRAM
  ld bc, $FFFE - _HRAM
  jp ClearData
