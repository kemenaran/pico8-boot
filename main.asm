; From https://gbdev.io/gb-asm-tutorial/part1/hello_world.html

INCLUDE "hardware.inc"
INCLUDE "constants.asm"

SECTION "Interrupt VBlank", ROM0[$0040]
  jp VBlankInterrupt

SECTION "Header", ROM0[$100]
  jp EntryPoint

ds $150 - @, 0 ; Make room for the header

EntryPoint:
  ; Switch CPU to double-speed if needed
  cp   BOOTUP_A_CGB ; running on Game Boy Color?
  jr   nz, .speedSwitchEnd
  ; Do we need to switch the CPU speed?
  ldh  a, [rKEY1]
  and  KEY1F_DBLSPEED
  jr   nz, .speedSwitchEnd
  ; Configure for double-speed
  ld   a, P1F_5 | P1F_4
  ldh  [rP1], a
  ld   a, KEY1F_PREPARE
  ldh  [rKEY1], a
  xor  a
  ldh  [rIE], a
  stop
.speedSwitchEnd

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

  ; Initialize stack
  ld sp, wStackTop

  ; Clear HRAM
  ld hl, _HRAM
  ld bc, $FFFE - _HRAM
  call ClearData

  ; Clear BG maps
  call ClearBGMap0
  call ClearBGMap1

  ; Fill initial attributes maps
  ld de, DefaultAttrmapBank0
  ld hl, _SCRN0
  ld bc, ATTRMAP_HEIGHT
  call CopyAttrmap

  ld de, DefaultAttrmapBank1
  ld hl, _SCRN1
  ld bc, ATTRMAP_HEIGHT
  call CopyAttrmap

  ; Initialize double-buffering
  ; (first frame will be written to VRAM bank 0)
  call SwapBuffers.presentBufferB

  ; Load a fully black screen for the first frame
  call LoadFrame0

  ; Present the first frame
  call SwapBuffersIfReady

  ; Turn the LCD on
  ld a, LCDCF_ON | LCDCF_BGON | LCDCF_BLK01
  ld [rLCDC], a

  ; During the first (blank) frame, initialize display registers
  ld a, %11100100
  ld [rBGP], a

  ; Configure interrupts
  di
  ld a, IEF_VBLANK
  ldh [rIE], a
  ei

  ; Start the main loop
  jp MainLoop

MainLoop:
  ; Stop the CPU until the next interrupt
  halt
  nop
  ; Ensure we actually reached v-blank
.ensureVBlank
  ld a, [rLY]
  cp $90 ; 144
  jp c, .ensureVBlank

  ; Loop
  jp MainLoop

; Executed by the VBlank interrupt handler
VBlankInterrupt:
  ; Increment the VI count
  ld hl, hVICount
  inc [hl]

  ; If we reached the last animation frame, return
  ld a, [hFrame]
  cp MAX_ANIMATION_FRAMES + 1
  jp z, .done

  ; Load the next data
  call ExecuteDataLoading

  ; If a new frame is ready, swap buffers
  call SwapBuffersIfReady

.done
  reti

; Execute a data-loading step on each VBlank.
;
; The data-loading step may result in a new frame being ready to be presented,
; or require additional loading steps during the next VBlank.
;
; This function must not execute longer than the VBlank duration.
ExecuteDataLoading:
  ; Execute the handler for the current VI
  ld a, [hVICount]
  call TableJump
  dw $0000
  dw LoadFrame1TilesetChunk1
  dw LoadFrame1TilesetChunk2
  dw LoadFrame1Tilemap
  dw PresentFrame1
  dw LoadFrame2TilesetChunk1
  dw LoadFrame2TilesetChunk2
  dw LoadFrame2Tilemap
  dw PresentFrame
  dw LoadFrame3TilesetChunk1
  dw LoadFrame3TilesetChunk2
  dw LoadFrame3Tilemap
  dw PresentFrame
  dw LoadFrame4TilesetChunk1
  dw LoadFrame4TilesetChunk2
  dw LoadFrame4Tilemap
  dw PresentFrame
  dw LoadFrame5TilesetChunk1
  dw LoadFrame5TilesetChunk2
  dw LoadFrame5Tilemap
  dw PresentFrame
  dw LoadFrame6Tilemap
  dw Delay
  dw Delay
  dw PresentFrame
  dw Delay ; should never be called
  dw Delay ; should never be called
  dw Delay ; should never be called

; Do nothing during this VBlank interrupt
Delay:
  ret

; Mark the frame as ready to be presented
PresentFrame:
  jp AnimationFrameReady

LoadFrame0:
  ld hl, BlackPalettes
  call CopyBGPalettes
  call AnimationFrameReady
  ret

LoadFrame1TilesetChunk1:
  call CopyTilesetForFrameStage
  ret

LoadFrame1TilesetChunk2:
  ld hl, hFrameStage
  inc [hl]
  call CopyTilesetForFrameStage
  ret

LoadFrame1Tilemap:
  call CopyBlackTile
  call CopyFrameTilemap
  ret

PresentFrame1:
  ; Loading the palettes must be the last thing we do before presenting the frame,
  ; because they are not double-buffered.
  ld hl, Pico8Palettes
  call CopyBGPalettes
  call AnimationFrameReady
  ret

LoadFrame2TilesetChunk1:
  call CopyTilesetForFrameStage
  ret

LoadFrame2TilesetChunk2:
  ld hl, hFrameStage
  inc [hl]
  call CopyTilesetForFrameStage
  ret

LoadFrame2Tilemap:
  call CopyBlackTile
  call CopyFrameTilemap
  ret

LoadFrame3TilesetChunk1:
  call CopyTilesetForFrameStage
  ret

LoadFrame3TilesetChunk2:
  ld hl, hFrameStage
  inc [hl]
  call CopyTilesetForFrameStage
  ret

LoadFrame3Tilemap:
  call CopyBlackTile
  call CopyFrameTilemap
  ret

LoadFrame4TilesetChunk1:
  call CopyTilesetForFrameStage
  ret

LoadFrame4TilesetChunk2:
  ld hl, hFrameStage
  inc [hl]
  call CopyTilesetForFrameStage
  ret

LoadFrame4Tilemap:
  call CopyBlackTile
  call CopyFrameTilemap
  ret

LoadFrame5TilesetChunk1:
  call CopyTilesetForFrameStage
  ret

LoadFrame5TilesetChunk2:
  ld hl, hFrameStage
  inc [hl]
  call CopyTilesetForFrameStage
  ret

LoadFrame5Tilemap:
  call CopyBlackTile
  call CopyFrameTilemap
  ret

LoadFrame6Tilemap:
  call CopyBlackTile
  call CopyFrameTilemap
  ret

CopyTilesetForFrameStage:
  ; bc = (hFrame * 2 + hFrameStage) * 2
  ld b, 0
  ld a, [hFrame]
  sla a
  ld hl, hFrameStage
  add a, [hl]
  sla a
  ld c, a
  ; bc = TilesetDefinitionsTable[bc]
  ld hl, TilesetDefinitionsTable
  add hl, bc
  ld a, [hli]
  ld c, a
  ld a, [hl]
  ld h, a
  ld l, c
  ; Switch to back-buffer VRAM bank
  ld a, [hTilesDataBankBack]
  ld [rVBK], a
  ; Copy
  call CopyTileset
  ; Restore front-buffer VRAM bank
  ld a, [hTilesDataBankFront]
  ld [rVBK], a
  ret

CopyFrameTilemap:
  ; bc = hFrame * 2
  ld b, 0
  ld a, [hFrame]
  sla a
  ld c, a
  ; de = source
  ld hl, TilemapsTable
  add hl, bc
  ld a, [hli]
  ld e, a
  ld a, [hl]
  ld d, a
  ; bc = rows count
  ld b, 0
  ld c, TILEMAP_HEIGHT
  ; hl = destination
  ld a, [hBGMapAddressBack]
  ld h, a
  ld l, TILEMAP_TOP * 32 + TILEMAP_LEFT
  ; Switch to VRAM bank 0
  xor a
  ld [rVBK], a
  ; Copy
  call CopyTilemap
  ; Restore front VRAM bank
  ld a, [hTilesDataBankFront]
  ld [rVBK], a
  ret

CopyBlackTile:
  ld hl, TilesetDefinitionBlackTile
  ; Switch to back VRAM bank
  ld a, [hTilesDataBankBack]
  ld [rVBK], a
  ; Copy
  call CopyTileset
  ; Restore front VRAM bank
  ld a, [hTilesDataBankFront]
  ld [rVBK], a
  ret

AnimationFrameReady:
  ; Mark the frame as ready for presentation
  ld a, 1
  ld [hNeedsPresentingFrame], a
  ret

IncrementAnimationFrame:
  ; Increment the animation frame index
  ld hl, hFrame
  inc [hl]
  ; Reset the loading stage
  xor a
  ld [hFrameStage], a
  ret

SwapBuffersIfReady:
  ; If no new frame is ready, present the same buffer
  ld a, [hNeedsPresentingFrame]
  and a
  ret z

  ; Swap buffers
  xor a
  ld [hNeedsPresentingFrame], a
  call IncrementAnimationFrame
  ; fallthrough

; Swap the front buffer and the back buffer (tile data and BG map)
SwapBuffers:
  ld a, [hTilesDataBankFront]
  and a
  jp z, .presentBufferB

.presentBufferA
  ; Tiles data is presented from VRAM bank 0
  ld a, 1
  ld [hTilesDataBankBack], a
  xor a
  ld [hTilesDataBankFront], a
  ; Switch to front VRAM bank
  ld [rVBK], a
  ; BG map is presented from $9800
  ld a, HIGH(_SCRN0)
  ld [hBGMapAddressFront], a
  ld a, HIGH(_SCRN1)
  ld [hBGMapAddressBack], a
  ; Switch BG map
  ld hl, rLCDC
  res LCDCB_BG9C00, [hl]
  ret

.presentBufferB
  ; Tiles data is presented from VRAM bank 1
  xor a
  ld [hTilesDataBankBack], a
  ld a, 1
  ld [hTilesDataBankFront], a
  ; Switch to front VRAM bank
  ld [rVBK], a
  ; BG map is presented from $9C00
  ld a, HIGH(_SCRN1)
  ld [hBGMapAddressFront], a
  ld a, HIGH(_SCRN0)
  ld [hBGMapAddressBack], a
  ; Switch BG map
  ld hl, rLCDC
  set LCDCB_BG9C00, [hl]
  ret

INCLUDE "table_jump.asm"
INCLUDE "memory.asm"
INCLUDE "gfx.asm"

; -------------------------------------------------------------------------------
; Tileset definitions

; Addresses of individual tilestruct definitions
; Indexed by hFrame * 2 + hFrameStage
TilesetDefinitionsTable:
._0_0 dw $0000
._0_1 dw $0000
._1_0 dw TilesetDefinitionFrame1Chunk1
._1_1 dw TilesetDefinitionFrame1Chunk2
._2_0 dw TilesetDefinitionFrame2Chunk1
._2_1 dw TilesetDefinitionFrame2Chunk2
._3_0 dw TilesetDefinitionFrame3Chunk1
._3_1 dw TilesetDefinitionFrame3Chunk2
._4_0 dw TilesetDefinitionFrame4Chunk1
._4_1 dw TilesetDefinitionFrame4Chunk2
._5_0 dw TilesetDefinitionFrame5Chunk1
._5_1 dw TilesetDefinitionFrame5Chunk2

DEF TILESET_1_CHUNKS_COUNT EQUS "(((Frame1Tiles.end - Frame1Tiles) / 16) / 2)"

TilesetDefinitionFrame1Chunk1:
.source      dw Frame1Tiles
.source_bank db BANK(Frame1Tiles)
.dest        dw _VRAM
.count       db TILESET_1_CHUNKS_COUNT

TilesetDefinitionFrame1Chunk2:
.source      dw Frame1Tiles + TILESET_1_CHUNKS_COUNT * 16
.source_bank db BANK(Frame1Tiles)
.dest        dw _VRAM + TILESET_1_CHUNKS_COUNT * 16
.count       db TILESET_1_CHUNKS_COUNT

DEF TILESET_2_1_CHUNKS_COUNT EQUS "128"
DEF TILESET_2_2_CHUNKS_COUNT EQUS "(((Frame2Tiles.end - Frame2Tiles) / 16) - TILESET_2_1_CHUNKS_COUNT)"

TilesetDefinitionFrame2Chunk1:
.source      dw Frame2Tiles
.source_bank db BANK(Frame2Tiles)
.dest        dw _VRAM
.count       db TILESET_2_1_CHUNKS_COUNT

TilesetDefinitionFrame2Chunk2:
.source      dw Frame2Tiles + TILESET_2_1_CHUNKS_COUNT * 16
.source_bank db BANK(Frame2Tiles)
.dest        dw _VRAM + TILESET_2_1_CHUNKS_COUNT * 16
.count       db TILESET_2_2_CHUNKS_COUNT

DEF TILESET_3_CHUNKS_COUNT EQUS "(((Frame3Tiles.end - Frame3Tiles) / 16) / 2)"

TilesetDefinitionFrame3Chunk1:
.source      dw Frame3Tiles
.source_bank db BANK(Frame3Tiles)
.dest        dw _VRAM
.count       db TILESET_3_CHUNKS_COUNT

TilesetDefinitionFrame3Chunk2:
.source      dw Frame3Tiles + TILESET_3_CHUNKS_COUNT * 16
.source_bank db BANK(Frame3Tiles)
.dest        dw _VRAM + TILESET_3_CHUNKS_COUNT * 16
.count       db TILESET_3_CHUNKS_COUNT

DEF TILESET_4_CHUNKS_COUNT EQUS "(((Frame4Tiles.end - Frame4Tiles) / 16) / 2)"

TilesetDefinitionFrame4Chunk1:
.source      dw Frame4Tiles
.source_bank db BANK(Frame4Tiles)
.dest        dw _VRAM
.count       db TILESET_4_CHUNKS_COUNT

TilesetDefinitionFrame4Chunk2:
.source      dw Frame4Tiles + TILESET_4_CHUNKS_COUNT * 16
.source_bank db BANK(Frame4Tiles)
.dest        dw _VRAM + TILESET_4_CHUNKS_COUNT * 16
.count       db TILESET_4_CHUNKS_COUNT

DEF TILESET_5_CHUNKS_COUNT EQUS "(((Frame5Tiles.end - Frame5Tiles) / 16) / 2)"

TilesetDefinitionFrame5Chunk1:
.source      dw Frame5Tiles
.source_bank db BANK(Frame5Tiles)
.dest        dw _VRAM
.count       db TILESET_5_CHUNKS_COUNT

TilesetDefinitionFrame5Chunk2:
.source      dw Frame5Tiles + TILESET_5_CHUNKS_COUNT * 16
.source_bank db BANK(Frame5Tiles)
.dest        dw _VRAM + TILESET_5_CHUNKS_COUNT * 16
.count       db TILESET_5_CHUNKS_COUNT

TilesetDefinitionBlackTile:
.source      dw BlackTile
.source_bank db BANK(BlackTile)
.dest        dw _VRAM + $1000 - 16 ; last tile of tiles data memory
.count       db (BlackTile.end - BlackTile) / 16

; -------------------------------------------------------------------------------
; "Tilemaps"

; Tilemap source addresses in ROM
; Indexed by hFrame
TilemapsTable:
._0 dw $0000 ; plain black
._1 dw Frame1Tilemap
._2 dw Frame2Tilemap
._3 dw Frame3Tilemap
._4 dw Frame4Tilemap
._5 dw Frame5Tilemap
._6 dw Frame6Tilemap

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
INCBIN "gfx/6.bw.tilemap"
  .end

; -------------------------------------------------------------------------------
; Attrmaps

DefaultAttrmapBank0:
  db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  db 0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 0, 0
  db 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 0, 0, 0
  db 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 0, 0, 0, 0
  db 0, 0, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 0, 0, 1, 0, 0
  db 0, 0, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 0, 0, 1, 1, 0, 0
  db 0, 0, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 0, 0, 1, 1, 2, 0, 0
  db 0, 0, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 0, 0, 1, 1, 2, 2, 0, 0
  db 0, 0, 3, 4, 4, 5, 5, 6, 6, 7, 7, 0, 0, 1, 1, 2, 2, 3, 0, 0
  db 0, 0, 4, 4, 5, 5, 6, 6, 7, 7, 0, 0, 1, 1, 2, 2, 3, 3, 0, 0
  db 0, 0, 4, 5, 5, 6, 6, 7, 7, 0, 0, 1, 1, 2, 2, 3, 3, 4, 0, 0
  db 0, 0, 5, 5, 6, 6, 7, 7, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 0, 0
  db 0, 0, 5, 6, 6, 7, 7, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 0, 0
  db 0, 0, 6, 6, 7, 7, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 0, 0
  db 0, 0, 6, 7, 7, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 0, 0
  db 0, 0, 7, 7, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 0, 0
  db 0, 0, 7, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 0, 0
  db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  .end

DEF AB1 EQU %00001000
DefaultAttrmapBank1:
  db AB1 | 0, AB1 | 0, AB1 | 0, AB1 | 0, AB1 | 0, AB1 | 0, AB1 | 0, AB1 | 0, AB1 | 0, AB1 | 0, AB1 | 0, AB1 | 0, AB1 | 0, AB1 | 0, AB1 | 0, AB1 | 0, AB1 | 0, AB1 | 0, AB1 | 0, AB1 | 0
  db AB1 | 0, AB1 | 0, AB1 | 0, AB1 | 0, AB1 | 1, AB1 | 1, AB1 | 2, AB1 | 2, AB1 | 3, AB1 | 3, AB1 | 4, AB1 | 4, AB1 | 5, AB1 | 5, AB1 | 6, AB1 | 6, AB1 | 7, AB1 | 7, AB1 | 0, AB1 | 0
  db AB1 | 0, AB1 | 0, AB1 | 0, AB1 | 1, AB1 | 1, AB1 | 2, AB1 | 2, AB1 | 3, AB1 | 3, AB1 | 4, AB1 | 4, AB1 | 5, AB1 | 5, AB1 | 6, AB1 | 6, AB1 | 7, AB1 | 7, AB1 | 0, AB1 | 0, AB1 | 0
  db AB1 | 0, AB1 | 0, AB1 | 1, AB1 | 1, AB1 | 2, AB1 | 2, AB1 | 3, AB1 | 3, AB1 | 4, AB1 | 4, AB1 | 5, AB1 | 5, AB1 | 6, AB1 | 6, AB1 | 7, AB1 | 7, AB1 | 0, AB1 | 0, AB1 | 0, AB1 | 0
  db AB1 | 0, AB1 | 0, AB1 | 1, AB1 | 2, AB1 | 2, AB1 | 3, AB1 | 3, AB1 | 4, AB1 | 4, AB1 | 5, AB1 | 5, AB1 | 6, AB1 | 6, AB1 | 7, AB1 | 7, AB1 | 0, AB1 | 0, AB1 | 1, AB1 | 0, AB1 | 0
  db AB1 | 0, AB1 | 0, AB1 | 2, AB1 | 2, AB1 | 3, AB1 | 3, AB1 | 4, AB1 | 4, AB1 | 5, AB1 | 5, AB1 | 6, AB1 | 6, AB1 | 7, AB1 | 7, AB1 | 0, AB1 | 0, AB1 | 1, AB1 | 1, AB1 | 0, AB1 | 0
  db AB1 | 0, AB1 | 0, AB1 | 2, AB1 | 3, AB1 | 3, AB1 | 4, AB1 | 4, AB1 | 5, AB1 | 5, AB1 | 6, AB1 | 6, AB1 | 7, AB1 | 7, AB1 | 0, AB1 | 0, AB1 | 1, AB1 | 1, AB1 | 2, AB1 | 0, AB1 | 0
  db AB1 | 0, AB1 | 0, AB1 | 3, AB1 | 3, AB1 | 4, AB1 | 4, AB1 | 5, AB1 | 5, AB1 | 6, AB1 | 6, AB1 | 7, AB1 | 7, AB1 | 0, AB1 | 0, AB1 | 1, AB1 | 1, AB1 | 2, AB1 | 2, AB1 | 0, AB1 | 0
  db AB1 | 0, AB1 | 0, AB1 | 3, AB1 | 4, AB1 | 4, AB1 | 5, AB1 | 5, AB1 | 6, AB1 | 6, AB1 | 7, AB1 | 7, AB1 | 0, AB1 | 0, AB1 | 1, AB1 | 1, AB1 | 2, AB1 | 2, AB1 | 3, AB1 | 0, AB1 | 0
  db AB1 | 0, AB1 | 0, AB1 | 4, AB1 | 4, AB1 | 5, AB1 | 5, AB1 | 6, AB1 | 6, AB1 | 7, AB1 | 7, AB1 | 0, AB1 | 0, AB1 | 1, AB1 | 1, AB1 | 2, AB1 | 2, AB1 | 3, AB1 | 3, AB1 | 0, AB1 | 0
  db AB1 | 0, AB1 | 0, AB1 | 4, AB1 | 5, AB1 | 5, AB1 | 6, AB1 | 6, AB1 | 7, AB1 | 7, AB1 | 0, AB1 | 0, AB1 | 1, AB1 | 1, AB1 | 2, AB1 | 2, AB1 | 3, AB1 | 3, AB1 | 4, AB1 | 0, AB1 | 0
  db AB1 | 0, AB1 | 0, AB1 | 5, AB1 | 5, AB1 | 6, AB1 | 6, AB1 | 7, AB1 | 7, AB1 | 0, AB1 | 0, AB1 | 1, AB1 | 1, AB1 | 2, AB1 | 2, AB1 | 3, AB1 | 3, AB1 | 4, AB1 | 4, AB1 | 0, AB1 | 0
  db AB1 | 0, AB1 | 0, AB1 | 5, AB1 | 6, AB1 | 6, AB1 | 7, AB1 | 7, AB1 | 0, AB1 | 0, AB1 | 1, AB1 | 1, AB1 | 2, AB1 | 2, AB1 | 3, AB1 | 3, AB1 | 4, AB1 | 4, AB1 | 5, AB1 | 0, AB1 | 0
  db AB1 | 0, AB1 | 0, AB1 | 6, AB1 | 6, AB1 | 7, AB1 | 7, AB1 | 0, AB1 | 0, AB1 | 1, AB1 | 1, AB1 | 2, AB1 | 2, AB1 | 3, AB1 | 3, AB1 | 4, AB1 | 4, AB1 | 5, AB1 | 5, AB1 | 0, AB1 | 0
  db AB1 | 0, AB1 | 0, AB1 | 6, AB1 | 7, AB1 | 7, AB1 | 0, AB1 | 0, AB1 | 1, AB1 | 1, AB1 | 2, AB1 | 2, AB1 | 3, AB1 | 3, AB1 | 4, AB1 | 4, AB1 | 5, AB1 | 5, AB1 | 6, AB1 | 0, AB1 | 0
  db AB1 | 0, AB1 | 0, AB1 | 7, AB1 | 7, AB1 | 0, AB1 | 0, AB1 | 1, AB1 | 1, AB1 | 2, AB1 | 2, AB1 | 3, AB1 | 3, AB1 | 4, AB1 | 4, AB1 | 5, AB1 | 5, AB1 | 6, AB1 | 6, AB1 | 0, AB1 | 0
  db AB1 | 0, AB1 | 0, AB1 | 7, AB1 | 0, AB1 | 0, AB1 | 1, AB1 | 1, AB1 | 2, AB1 | 2, AB1 | 3, AB1 | 3, AB1 | 4, AB1 | 4, AB1 | 5, AB1 | 5, AB1 | 6, AB1 | 6, AB1 | 7, AB1 | 0, AB1 | 0
  db AB1 | 0, AB1 | 0, AB1 | 0, AB1 | 0, AB1 | 0, AB1 | 0, AB1 | 0, AB1 | 0, AB1 | 0, AB1 | 0, AB1 | 0, AB1 | 0, AB1 | 0, AB1 | 0, AB1 | 0, AB1 | 0, AB1 | 0, AB1 | 0, AB1 | 0, AB1 | 0

; -------------------------------------------------------------------------------
SECTION "Tilesets - frame 1-4", ROMX, BANK[$01]

ALIGN 4 ; Align to 16-bytes boundaries, for HDMA transfer
BlackTile:
  db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  .end

ALIGN 4
Frame1Tiles:
INCBIN "gfx/1.bw.tileset.2bpp"
  .end

ALIGN 4
Frame2Tiles:
INCBIN "gfx/2.bw.tileset.2bpp"
  .end

ALIGN 4
Frame3Tiles:
INCBIN "gfx/3.bw.tileset.2bpp"
  .end

ALIGN 4
Frame4Tiles:
INCBIN "gfx/4.bw.tileset.2bpp"
  .end

; -------------------------------------------------------------------------------
SECTION "Tilesets - frame 5", ROMX, BANK[$02]

ALIGN 4
Frame5Tiles:
INCBIN "gfx/5.bw.tileset.2bpp"
  .end

; -------------------------------------------------------------------------------
SECTION "WRAM Stack", WRAM0[$CE00]

; Bottom of WRAM is used as the stack
wStack::
  ds $CFFF - @ + 1

; Init puts the SP here
DEF wStackTop EQU $CFFF

; -------------------------------------------------------------------------------
SECTION "HRAM", HRAM[$FF80]

; Number of vertical interrupts that occured
hVICount: ds 1

; Index of the animation frame being rendered
; (the frame being presented is the previous one)
hFrame: ds 1

; Index of the loading stage of the animation frame being rendered
hFrameStage: ds 1

; Whether there's a frame ready to be presented
hNeedsPresentingFrame: ds 1

; VRAM bank for tiles data currently presented (0 or 1)
hTilesDataBankFront: ds 1
; VRAM bank for tiles data currently rendered into (0 or 1)
hTilesDataBankBack: ds 1

; High-byte of the BG map area currently presented
hBGMapAddressFront: ds 1
; High-byte of the BG map area currently rendered into
hBGMapAddressBack: ds 1
