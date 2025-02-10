; -------------------------------------------------------------------------------
; Animated picture definition

AnimationStruct:
.struct
.framesCount
  db 2
.frames
  dw Frame0
  dw Frame1

Frame0:
.duration       db 6
.tilesetAddress dw Frame0Tiles
.tilesetBank    db BANK(Frame0Tiles)
.tilesetCount   db (Frame0Tiles.end - Frame0Tiles) / 16
.tilemapAddress dw Frame0Tilemap
.tilemapBank    db BANK(Frame0Tilemap)

Frame1:
.duration       db 6
.tilesetAddress dw Frame1Tiles
.tilesetBank    db BANK(Frame1Tiles)
.tilesetCount   db (Frame1Tiles.end - Frame1Tiles) / 16
.tilemapAddress dw Frame1Tilemap
.tilemapBank    db BANK(Frame1Tilemap)

; -------------------------------------------------------------------------------
; Tilemaps data

Frame0Tilemap:
  ds TILEMAP_WIDTH * TILEMAP_HEIGHT, $00 ; all black
.end

Frame1Tilemap:
INCBIN "gfx/1.bw.tilemap"
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
