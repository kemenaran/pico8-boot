; -------------------------------------------------------------------------------
; Animated picture definition

AnimationStruct:
.struct
.framesCount
  db 7
.frames
  dw Frame0
  dw Frame1
  dw Frame2
  dw Frame3
  dw Frame4
  dw Frame5
  dw Frame6

Frame0:
.duration       db 4 * ANIMATION_SPEED_FACTOR
.tilesetAddress dw Frame0Tiles
.tilesetBank    db BANK(Frame0Tiles)
.tilesetCount   db (Frame0Tiles.end - Frame0Tiles) / 16
.tilemapAddress dw Frame0Tilemap
.tilemapBank    db BANK(Frame0Tilemap)

Frame1:
.duration       db 4 * ANIMATION_SPEED_FACTOR
.tilesetAddress dw Frame1Tiles
.tilesetBank    db BANK(Frame1Tiles)
.tilesetCount   db (Frame1Tiles.end - Frame1Tiles) / 16
.tilemapAddress dw Frame1Tilemap
.tilemapBank    db BANK(Frame1Tilemap)

Frame2:
.duration       db 4 * ANIMATION_SPEED_FACTOR
.tilesetAddress dw Frame2Tiles
.tilesetBank    db BANK(Frame2Tiles)
.tilesetCount   db (Frame2Tiles.end - Frame2Tiles) / 16
.tilemapAddress dw Frame2Tilemap
.tilemapBank    db BANK(Frame2Tilemap)

Frame3:
.duration       db 4 * ANIMATION_SPEED_FACTOR
.tilesetAddress dw Frame3Tiles
.tilesetBank    db BANK(Frame3Tiles)
.tilesetCount   db (Frame3Tiles.end - Frame3Tiles) / 16
.tilemapAddress dw Frame3Tilemap
.tilemapBank    db BANK(Frame3Tilemap)

Frame4:
.duration       db 4 * ANIMATION_SPEED_FACTOR
.tilesetAddress dw Frame4Tiles
.tilesetBank    db BANK(Frame4Tiles)
.tilesetCount   db (Frame4Tiles.end - Frame4Tiles) / 16
.tilemapAddress dw Frame4Tilemap
.tilemapBank    db BANK(Frame4Tilemap)

Frame5:
.duration       db 4 * ANIMATION_SPEED_FACTOR
.tilesetAddress dw Frame5Tiles
.tilesetBank    db BANK(Frame5Tiles)
.tilesetCount   db (Frame5Tiles.end - Frame5Tiles) / 16
.tilemapAddress dw Frame5Tilemap
.tilemapBank    db BANK(Frame5Tilemap)

Frame6:
.duration       db 4 * ANIMATION_SPEED_FACTOR
.tilesetAddress dw Frame6Tiles
.tilesetBank    db BANK(Frame6Tiles)
.tilesetCount   db (Frame6Tiles.end - Frame6Tiles) / 16
.tilemapAddress dw Frame6Tilemap
.tilemapBank    db BANK(Frame6Tilemap)

; -------------------------------------------------------------------------------
; Tilemaps data

Frame0Tilemap:
  ds TILEMAP_WIDTH * TILEMAP_HEIGHT, $00 ; all black
.end

Frame1Tilemap:
INCBIN "gfx/1.bw.tilemap"
.end

Frame2Tilemap:
INCBIN "gfx/2.bw.tilemap"
.end

Frame3Tilemap:
INCBIN "gfx/3.bw.tilemap"
.end

Frame4Tilemap:
INCBIN "gfx/4.bw.tilemap"
.end

Frame5Tilemap:
INCBIN "gfx/5.bw.tilemap"
.end

Frame6Tilemap:
  ds TILEMAP_WIDTH * TILEMAP_HEIGHT, $00 ; all black
.end

; -------------------------------------------------------------------------------
; Attrmaps

DefaultAttrmapBG0:
  ; First row
  ds ATTRMAP_WIDTH, $07
  ; Colored rows
  REPT 16
  ds ATTRMAP_WIDTH, $00, $01, $02, $03, $04, $05, $06, $07
  ENDR
  ; Last row
  ds ATTRMAP_WIDTH, $07
.end

DEF BG_VBK_1 = %00001000
DefaultAttrmapBG1:
  ; First row
  ds ATTRMAP_WIDTH, $07 | BG_VBK_1
  ; Colored rows
  REPT 16
  ds ATTRMAP_WIDTH, $00 | BG_VBK_1, $01 | BG_VBK_1, $02 | BG_VBK_1, $03 | BG_VBK_1, $04 | BG_VBK_1, $05 | BG_VBK_1, $06 | BG_VBK_1, $07 | BG_VBK_1
  ENDR
  ; Last row
  ds ATTRMAP_WIDTH, $07 | BG_VBK_1
.end

; -------------------------------------------------------------------------------
SECTION "Tilesets - frame 1-4", ROMX, BANK[$01]

align 4 ; Align to 16-bytes boundaries, for HDMA transfer
BlackTile:
  ds 16, $FF
.end

ds align[4]
Frame0Tiles:
  ds 16, $FF
.end

ds align[4]
Frame1Tiles:
  INCBIN "gfx/1.bw.tileset.2bpp"
.end

ds align[4]
Frame2Tiles:
  INCBIN "gfx/2.bw.tileset.2bpp"
.end

ds align[4]
Frame3Tiles:
  INCBIN "gfx/3.bw.tileset.2bpp"
.end

ds align[4]
Frame4Tiles:
  INCBIN "gfx/4.bw.tileset.2bpp"
.end

; -------------------------------------------------------------------------------
SECTION "Tilesets - frame 5-6", ROMX, BANK[$02]

ds align[4]
Frame5Tiles:
  INCBIN "gfx/5.bw.tileset.2bpp"
.end

ds align[4]
Frame6Tiles:
  ds 16, $FF
.end
