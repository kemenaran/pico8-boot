; From https://gbdev.io/gb-asm-tutorial/part1/hello_world.html

INCLUDE "hardware.inc"
INCLUDE "header.asm"

; Tilemap layout, in tiles
DEF TILEMAP_WIDTH  EQU 16
DEF TILEMAP_HEIGHT EQU 16
DEF TILEMAP_TOP    EQU 1
DEF TILEMAP_LEFT   EQU 2

; Number of frames in the animation
DEF MAX_ANIMATION_FRAMES EQU 5

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

  ; Clear BG maps 0 and 1
  ld de, _SCRN0
  ld bc, _SRAM - _SCRN0
  ld a, $FF
  call FillData

  ; Clear attributes maps
  ld a, 1
  ld [rVBK], a
  ; Clear Attr map 0 (load tiles from VRAM bank 0)
  ld de, _SCRN0
  ld bc, _SCRN1 - _SCRN0
  ld a, %00000000
  call FillData
  ; Clear Attr map 1 (load tiles from VRAM bank 1)
  ld de, _SCRN1
  ld bc, _SRAM - _SCRN1
  ld a, %00001000
  call FillData
  xor a
  ld [rVBK], a

  ; Initialize double-buffering
  ; (first frame will be written to VRAM bank 0)
  call SwapBuffers.presentBufferB

  ; Load default DMG-on-CGB palettes
  call LoadDefaultPalettes

  call LoadFrame0

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

  ; Increment the VI count
  ld hl, hVICount
  inc [hl]

  ; If we reached the last animation frame, return
  ld a, [hFrame]
  cp MAX_ANIMATION_FRAMES
  jp z, MainLoop

  ; If the new frame is ready, swap buffers
  ld a, [hNeedsPresentingFrame]
  and a
  jp z, .swapBuffersEnd
.swapBuffers
  xor a
  ld [hNeedsPresentingFrame], a
  call SwapBuffers
  call IncrementAnimationFrame
.swapBuffersEnd

  ; Load the next data
  ; (this might or might not result in a new frame being ready)
  call ExecuteDataLoading

  ; Loop
  jp MainLoop

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
  dw LoadFrame0
  dw LoadFrame1TilesetChunk1
  dw LoadFrame1TilesetChunk2
  dw LoadFrame1Tilemap
  dw PresentFrame
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
  dw LoadFrame5
; todo: add other frames

; Do nothing during this VBlank interrupt
Delay:
  ret

; Mark the frame as ready to be presented
PresentFrame:
  jp AnimationFrameReady

; Frame 0 loads while the screen is turned off.
LoadFrame0:
  ; Frame 0 is plain black, and the tilemap is aready cleared: nothing else to do
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

LoadFrame5:
  ; TODO
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

; 8 identical DMG-like palettes
DefaultBGPalettes:
  dw $7FFF, $5EF7, $3DEF, $0000
  dw $7FFF, $5EF7, $3DEF, $0000
  dw $7FFF, $5EF7, $3DEF, $0000
  dw $7FFF, $5EF7, $3DEF, $0000
  dw $7FFF, $5EF7, $3DEF, $0000
  dw $7FFF, $5EF7, $3DEF, $0000
  dw $7FFF, $5EF7, $3DEF, $0000
  dw $7FFF, $5EF7, $3DEF, $0000
  .end

LoadDefaultPalettes:
  ld hl, DefaultBGPalettes
  call CopyBGPalettes
  ret

 ; Writes $40 bytes located at HL to the BG palettes.
 ; Only available during V-Blank.
 CopyBGPalettes:
  ld a, BCPSF_AUTOINC | 0
  ldh [rBGPI], a
  ld b, DefaultBGPalettes.end - DefaultBGPalettes
.loop
  ld a, [hli]
  ldh [rBGPD] ,a
  dec b
  jr nz, .loop
  ret

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

; -------------------------------------------------------------------------------
SECTION "Tilemap", ROM0

; Tilemap source addresses in ROM
; Indexed by hFrame
TilemapsTable:
._0 dw $0000 ; plain black
._1 dw Frame1Tilemap
._2 dw Frame2Tilemap
._3 dw Frame3Tilemap
._4 dw Frame4Tilemap

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

; -------------------------------------------------------------------------------
SECTION "Tile data", ROMX, BANK[$01]

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

DEF TILESET_1_CHUNKS_COUNT EQUS "(((Frame1Tiles.end - Frame1Tiles) / 16) / 2)"

TilesetDefinitionFrame1Chunk1:
.source dw Frame1Tiles
.dest   dw _VRAM
.count  db TILESET_1_CHUNKS_COUNT

TilesetDefinitionFrame1Chunk2:
.source dw Frame1Tiles + TILESET_1_CHUNKS_COUNT * 16
.dest   dw _VRAM + TILESET_1_CHUNKS_COUNT * 16
.count  db TILESET_1_CHUNKS_COUNT

DEF TILESET_2_1_CHUNKS_COUNT EQUS "128"
DEF TILESET_2_2_CHUNKS_COUNT EQUS "(((Frame2Tiles.end - Frame2Tiles) / 16) - TILESET_2_1_CHUNKS_COUNT)"

TilesetDefinitionFrame2Chunk1:
.source dw Frame2Tiles
.dest   dw _VRAM
.count  db TILESET_2_1_CHUNKS_COUNT

TilesetDefinitionFrame2Chunk2:
.source dw Frame2Tiles + TILESET_2_1_CHUNKS_COUNT * 16
.dest   dw _VRAM + TILESET_2_1_CHUNKS_COUNT * 16
.count  db TILESET_2_2_CHUNKS_COUNT

DEF TILESET_3_CHUNKS_COUNT EQUS "(((Frame3Tiles.end - Frame3Tiles) / 16) / 2)"

TilesetDefinitionFrame3Chunk1:
.source dw Frame3Tiles
.dest   dw _VRAM
.count  db TILESET_3_CHUNKS_COUNT

TilesetDefinitionFrame3Chunk2:
.source dw Frame3Tiles + TILESET_3_CHUNKS_COUNT * 16
.dest   dw _VRAM + TILESET_3_CHUNKS_COUNT * 16
.count  db TILESET_3_CHUNKS_COUNT

DEF TILESET_4_CHUNKS_COUNT EQUS "(((Frame4Tiles.end - Frame4Tiles) / 16) / 2)"

TilesetDefinitionFrame4Chunk1:
.source dw Frame4Tiles
.dest   dw _VRAM
.count  db TILESET_4_CHUNKS_COUNT

TilesetDefinitionFrame4Chunk2:
.source dw Frame4Tiles + TILESET_4_CHUNKS_COUNT * 16
.dest   dw _VRAM + TILESET_4_CHUNKS_COUNT * 16
.count  db TILESET_4_CHUNKS_COUNT

TilesetDefinitionBlackTile:
.source dw BlackTile
.dest   dw _VRAM + $1000 - 16 ; last tile of tiles data memory
.count  db (BlackTile.end - BlackTile) / 16

ALIGN 4 ; Align to 16-bytes boundaries, for HDMA transfer
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

ALIGN 4
BlackTile:
  db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
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
