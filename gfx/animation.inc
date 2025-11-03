; -------------------------------------------------------------------------------
; Animated picture definition

SECTION "Animation definitions", ROM0

AnimationStruct:
.struct
.framesCount
  db 11
.frames
  dw Frame0
  dw Frame1
  dw Frame2
  dw Frame3
  dw Frame4
  dw Frame5
  dw Frame6
  dw Frame7
  dw Frame8
  dw Frame9
  dw Frame10

Frame0:
.duration         db 7
.tilesetAddress   dw BlackTile
.tilesetBank      db BANK(BlackTile)
.tilesetCount     db (BlackTile.end - BlackTile) / 16
.tilemapAddress   dw BlackTilemap
.tilemapBank      db BANK(BlackTilemap)
.palettesAddress  dw BlackPalettes
.palettesBank     db BANK(BlackPalettes)
.palettesDiff     dw $0000
.palettesDiffBank db 0

Frame1:
.duration         db 7
.tilesetAddress   dw Frame1Tiles
.tilesetBank      db BANK(Frame1Tiles)
.tilesetCount     db (Frame1Tiles.end - Frame1Tiles) / 16
.tilemapAddress   dw Frame1Tilemap
.tilemapBank      db BANK(Frame1Tilemap)
.palettesAddress  dw Frame1InitialPalettes
.palettesBank     db BANK(Frame1InitialPalettes)
.palettesDiff     dw Frame1PalettesDiffs
.palettesDiffBank db BANK(Frame1PalettesDiffs)

Frame2:
.duration         db 5
.tilesetAddress   dw Frame2Tiles
.tilesetBank      db BANK(Frame2Tiles)
.tilesetCount     db (Frame2Tiles.end - Frame2Tiles) / 16
.tilemapAddress   dw Frame2Tilemap
.tilemapBank      db BANK(Frame2Tilemap)
.palettesAddress  dw Frame2InitialPalettes
.palettesBank     db BANK(Frame2InitialPalettes)
.palettesDiff     dw Frame2PalettesDiffs
.palettesDiffBank db BANK(Frame2PalettesDiffs)

Frame3:
.duration         db 3
.tilesetAddress   dw Frame3Tiles
.tilesetBank      db BANK(Frame3Tiles)
.tilesetCount     db (Frame3Tiles.end - Frame3Tiles) / 16
.tilemapAddress   dw Frame3Tilemap
.tilemapBank      db BANK(Frame3Tilemap)
.palettesAddress  dw Frame3InitialPalettes
.palettesBank     db BANK(Frame3InitialPalettes)
.palettesDiff     dw Frame3PalettesDiffs
.palettesDiffBank db BANK(Frame3PalettesDiffs)

Frame4:
.duration         db 5
.tilesetAddress   dw Frame4Tiles
.tilesetBank      db BANK(Frame4Tiles)
.tilesetCount     db (Frame4Tiles.end - Frame4Tiles) / 16
.tilemapAddress   dw Frame4Tilemap
.tilemapBank      db BANK(Frame4Tilemap)
.palettesAddress  dw Frame4InitialPalettes
.palettesBank     db BANK(Frame4InitialPalettes)
.palettesDiff     dw Frame4PalettesDiffs
.palettesDiffBank db BANK(Frame4PalettesDiffs)

Frame5:
.duration         db 7
.tilesetAddress   dw Frame5Tiles
.tilesetBank      db BANK(Frame5Tiles)
.tilesetCount     db (Frame5Tiles.end - Frame5Tiles) / 16
.tilemapAddress   dw Frame5Tilemap
.tilemapBank      db BANK(Frame5Tilemap)
.palettesAddress  dw Frame5InitialPalettes
.palettesBank     db BANK(Frame5InitialPalettes)
.palettesDiff     dw Frame5PalettesDiffs
.palettesDiffBank db BANK(Frame5PalettesDiffs)

Frame6:
.duration         db 30
.tilesetAddress   dw Frame6Tiles
.tilesetBank      db BANK(Frame6Tiles)
.tilesetCount     db (Frame6Tiles.end - Frame6Tiles) / 16
.tilemapAddress   dw Frame6Tilemap
.tilemapBank      db BANK(Frame6Tilemap)
.palettesAddress  dw Frame6InitialPalettes
.palettesBank     db BANK(Frame6InitialPalettes)
.palettesDiff     dw $0000
.palettesDiffBank db 0

Frame7:
.duration         db 9
.tilesetAddress   dw Frame7Tiles
.tilesetBank      db BANK(Frame7Tiles)
.tilesetCount     db (Frame7Tiles.end - Frame7Tiles) / 16
.tilemapAddress   dw Frame7Tilemap
.tilemapBank      db BANK(Frame7Tilemap)
.palettesAddress  dw Frame7InitialPalettes
.palettesBank     db BANK(Frame7InitialPalettes)
.palettesDiff     dw Frame7PalettesDiffs
.palettesDiffBank db BANK(Frame7PalettesDiffs)

Frame8:
.duration         db 2
.tilesetAddress   dw Frame8Tiles
.tilesetBank      db BANK(Frame8Tiles)
.tilesetCount     db (Frame8Tiles.end - Frame8Tiles) / 16
.tilemapAddress   dw Frame8Tilemap
.tilemapBank      db BANK(Frame8Tilemap)
.palettesAddress  dw Frame8InitialPalettes
.palettesBank     db BANK(Frame8InitialPalettes)
.palettesDiff     dw Frame8PalettesDiffs
.palettesDiffBank db BANK(Frame8PalettesDiffs)

Frame9:
.duration         db 9
.tilesetAddress   dw Frame9Tiles
.tilesetBank      db BANK(Frame9Tiles)
.tilesetCount     db (Frame9Tiles.end - Frame9Tiles) / 16
.tilemapAddress   dw Frame9Tilemap
.tilemapBank      db BANK(Frame9Tilemap)
.palettesAddress  dw Frame9InitialPalettes
.palettesBank     db BANK(Frame9InitialPalettes)
.palettesDiff     dw Frame9PalettesDiffs
.palettesDiffBank db BANK(Frame9PalettesDiffs)

Frame10:
.duration         db 10
.tilesetAddress   dw Frame10Tiles
.tilesetBank      db BANK(Frame10Tiles)
.tilesetCount     db (Frame10Tiles.end - Frame10Tiles) / 16
.tilemapAddress   dw Frame10Tilemap
.tilemapBank      db BANK(Frame10Tilemap)
.palettesAddress  dw Frame10InitialPalettes
.palettesBank     db BANK(Frame10InitialPalettes)
.palettesDiff     dw Frame10PalettesDiffs
.palettesDiffBank db BANK(Frame10PalettesDiffs)

; -------------------------------------------------------------------------------
; Tilemaps data
; (aligned to 16-bytes boundaries, for DMA transfers)

SECTION "Tilemap 0", ROMX, ALIGN[4]
BlackTilemap: ds TILEMAP_WIDTH * TILEMAP_HEIGHT, $00 ; all black
.end

SECTION "Tilemap 1", ROMX, ALIGN[4]
Frame1Tilemap: INCBIN "gfx/1.tilemap"
.end

SECTION "Tilemap 2", ROMX, ALIGN[4]
Frame2Tilemap: INCBIN "gfx/2.tilemap"
.end

SECTION "Tilemap 3", ROMX, ALIGN[4]
Frame3Tilemap: INCBIN "gfx/3.tilemap"
.end

SECTION "Tilemap 4", ROMX, ALIGN[4]
Frame4Tilemap: INCBIN "gfx/4.tilemap"
.end

SECTION "Tilemap 5", ROMX, ALIGN[4]
Frame5Tilemap: INCBIN "gfx/5.tilemap"
.end

SECTION "Tilemap 6", ROMX, ALIGN[4]
Frame6Tilemap: INCBIN "gfx/6.tilemap"
.end

SECTION "Tilemap 7", ROMX, ALIGN[4]
Frame7Tilemap: INCBIN "gfx/7.tilemap"
.end

SECTION "Tilemap 8", ROMX, ALIGN[4]
Frame8Tilemap: INCBIN "gfx/8.tilemap"
.end

SECTION "Tilemap 9", ROMX, ALIGN[4]
Frame9Tilemap: INCBIN "gfx/9.tilemap"
.end

SECTION "Tilemap 10", ROMX, ALIGN[4]
Frame10Tilemap: INCBIN "gfx/10.tilemap"
.end

; -------------------------------------------------------------------------------
; Attrmaps

SECTION "Attrmaps", ROMX

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
; Tilesets
; (aligned to 16-bytes boundaries, for DMA transfers)
SECTION "Black tile", ROMX, ALIGN[4]
BlackTile: ds 16, $FF
.end

SECTION "Tiles 1", ROMX, ALIGN[4]
Frame1Tiles: INCBIN "gfx/1.tileset.2bpp"
.end

SECTION "Tiles 2", ROMX, ALIGN[4]
Frame2Tiles: INCBIN "gfx/2.tileset.2bpp"
.end

SECTION "Tiles 3", ROMX, ALIGN[4]
Frame3Tiles: INCBIN "gfx/3.tileset.2bpp"
.end

SECTION "Tiles 4", ROMX, ALIGN[4]
Frame4Tiles: INCBIN "gfx/4.tileset.2bpp"
.end

SECTION "Tiles 5", ROMX, ALIGN[4]
Frame5Tiles: INCBIN "gfx/5.tileset.2bpp"
.end

SECTION "Tiles 6", ROMX, ALIGN[4]
Frame6Tiles: INCBIN "gfx/6.tileset.2bpp"
.end

SECTION "Tiles 7", ROMX, ALIGN[4]
Frame7Tiles: INCBIN "gfx/7.tileset.2bpp"
.end

SECTION "Tiles 8", ROMX, ALIGN[4]
Frame8Tiles: INCBIN "gfx/8.tileset.2bpp"
.end

SECTION "Tiles 9", ROMX, ALIGN[4]
Frame9Tiles: INCBIN "gfx/9.tileset.2bpp"
.end

SECTION "Tiles 10", ROMX, ALIGN[4]
Frame10Tiles: INCBIN "gfx/10.tileset.2bpp"
.end

; -------------------------------------------------------------------------------
; Palettes

INCLUDE "gfx/1.palettes.asm"
INCLUDE "gfx/2.palettes.asm"
INCLUDE "gfx/3.palettes.asm"
INCLUDE "gfx/4.palettes.asm"
INCLUDE "gfx/5.palettes.asm"
INCLUDE "gfx/6.palettes.asm"
INCLUDE "gfx/7.palettes.asm"
INCLUDE "gfx/8.palettes.asm"
INCLUDE "gfx/9.palettes.asm"
INCLUDE "gfx/10.palettes.asm"
