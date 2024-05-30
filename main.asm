; From https://gbdev.io/gb-asm-tutorial/part1/hello_world.html

INCLUDE "hardware.inc"

SECTION "Header", ROM0[$100]

  jp EntryPoint

  ds $150 - @, 0 ; Make room for the header

INCLUDE "memory.asm"

EntryPoint:
  ; Shut down audio circuitry
  ld a, 0
  ld [rNR52], a

  ; Do not turn the LCD off outside of VBlank
.waitVBlank
  ld a, [rLY]
  cp 144
  jp c, .waitVBlank

  ; Turn the LCD off
  ld a, 0
  ld [rLCDC], a

  ; Clear BG map 0
  ld bc, _SCRN1 - _SCRN0
  ld a, $FF
  call FillBGMap

  ; Copy the tile data
  ld hl, Tiles
  ld de, _VRAM
  ld bc, TilesEnd - Tiles
  call CopyData

  ld hl, BlackTile
  ld de, _VRAM + $1000 - 16 ; last tile of VRAM block 1
  ld bc, BlackTileEnd - BlackTile
  call CopyData

  ; Copy the tilemap
  ld de, Tilemap
  ld hl, _SCRN0 + TILEMAP_TOP * 32 + TILEMAP_LEFT
  ld bc, TilemapEnd - Tilemap

CopyTilemap:
  ld a, [de]
  ld [hli], a
  inc de
  dec bc
  ; If reaching the end of a tilemap row, jump to next BG row
  ld a, c
  and (TILEMAP_WIDTH - 1)
  jp nz, .rowEndIf
  push bc
  ld bc, (SCRN_VX_B - TILEMAP_WIDTH)
  add hl, bc
  pop bc
  .rowEndIf
  ; If not at the tilemap end yet, loop
  ld a, b
  or a, c
  jp nz, CopyTilemap

  ; Turn the LCD on
  ld a, LCDCF_ON | LCDCF_BGON | LCDCF_BLK01
  ld [rLCDC], a

  ; During the first (blank) frame, initialize display registers
  ld a, %11100100
  ld [rBGP], a

Done:
  jp Done


SECTION "Tile data", ROM0

Tiles:
INCBIN "gfx/1.bw.tileset.2bpp"
TilesEnd:

BlackTile:
db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
BlackTileEnd:

SECTION "Tilemap", ROM0
DEF TILEMAP_WIDTH EQU 16
DEF TILEMAP_TOP EQU 1
DEF TILEMAP_LEFT EQU 2
Tilemap:
INCBIN "gfx/1.bw.tilemap"
TilemapEnd:

