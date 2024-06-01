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

; Fill HRAM with 0
ClearHRAM:
  ld hl, _HRAM
  ld bc, $FFFE - _HRAM
  jp ClearData
