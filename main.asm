; From https://gbdev.io/gb-asm-tutorial/part1/hello_world.html

INCLUDE "hardware.inc"
INCLUDE "header.asm"
INCLUDE "memory.asm"

; Memory constants
DEF TILES_DATA_0 EQU $8000
DEF TILES_DATA_1 EQU $8800

; Tilemap layout, in tiles
DEF TILEMAP_WIDTH EQU 16
DEF TILEMAP_TOP   EQU 1
DEF TILEMAP_LEFT  EQU 2

; Number of frames in the animation
DEF MAX_FRAMES_COUNT EQU 2

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

  ; Initialize stack
  ld sp, wStackTop

  ; Clear memory
  call ClearHRAM

  ; Clear BG maps 0 and 1
  ld bc, _SRAM - _SCRN0
  ld a, $FF
  call FillBGMap

  ; Initialize double-buffering
  ; (first frame will be written to VRAM bank 0)
  call SwapBuffers.presentBufferB

  ; Load the first frame
  call LoadFrame

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

  ; Start the render loop
  jp MainLoop.waitForNextVBlank

MainLoop:
  call LoadNextFrame

.waitForNextVBlank
  ; Stop the CPU until the next interrupt
  halt
  nop
  ; Ensure we actually reached v-blank
.ensureVBlank
  ld a, [rLY]
  cp 144
  jp c, .ensureVBlank

  ; If the new frame is not ready, skip this frame, and wait for the next vblank interrupt
  ld a, [hNeedsPresentingFrame]
  and a
  jp z, .waitForNextVBlank

  xor a
  ld [hNeedsPresentingFrame], a

  ; Swap buffers
  call SwapBuffers

  ; Start rendering a new frame
  jp MainLoop

LoadNextFrame:
  ; If we reached the last frame, return
  ld a, [hFrameIndex]
  cp MAX_FRAMES_COUNT - 1
  ret z

  ; Increment the frame index
  inc a
  ld [hFrameIndex], a
  ; fallthrough

LoadFrame:
  call CopyFrameTileset
  call CopyFrameTilemap
  call CopyBlackTile

  ld a, 1
  ld [hNeedsPresentingFrame], a

  ret

CopyFrameTileset:
  ; bc = hFrameIndex * 2
  ld b, 0
  ld a, [hFrameIndex]
  sla a
  ld c, a
  ; hl = source
  ld hl, TilesetsTable
  add hl, bc
  ld a, [hli]
  ld e, a
  ld a, [hl]
  ld d, a
  ld h, d
  ld l, e
  ; de = destination
  ld de, _VRAM
  ; bc = count
  push hl
  ld hl, TilesetsSizeTable
  add hl, bc
  ld a, [hli]
  ld c, a
  ld a, [hl]
  ld b, a
  pop hl
  ; Switch to back VRAM bank
  ld a, [hTilesDataBankBack]
  ld [rVBK], a
  ; Copy
  call CopyData
  ; Restore front VRAM bank
  ld a, [hTilesDataBankFront]
  ld [rVBK], a
  ret

CopyFrameTilemap:
  ; bc = hFrameIndex * 2
  ld b, 0
  ld a, [hFrameIndex]
  sla a
  ld c, a
  ; de = source
  ld hl, TilemapsTable
  add hl, bc
  ld a, [hli]
  ld e, a
  ld a, [hl]
  ld d, a
  ; bc = count
  ld hl, TilemapsSizeTable
  add hl, bc
  ld a, [hli]
  ld c, a
  ld a, [hl]
  ld b, a
  ; hl = destination
  ld a, [hBGMapAddressBack]
  ld h, a
  ld l, TILEMAP_TOP * 32 + TILEMAP_LEFT
  ; Copy
  jp CopyTilemap

; Copy a tilemap from de to hl (a rectangular region of VRAM)
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
  ret

CopyBlackTile:
  ; hl = origin
  ld hl, BlackTile
  ; de = destination (last tile of tiles backbuffer)
  ld de, TILES_DATA_0 + $1000 - 16
.altBufferEndIf
  ld bc, BlackTile.end - BlackTile
  jp CopyData

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
  ; Switch VRAM bank
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
  ; Switch VRAM bank
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

; -------------------------------------------------------------------------------
SECTION "Tile data", ROM0

TilesetsTable:
._0 dw Frame1Tiles
._1 dw Frame2Tiles

TilesetsSizeTable:
._0 dw Frame1Tiles.end - Frame1Tiles
._1 dw Frame2Tiles.end - Frame2Tiles

Frame1Tiles:
INCBIN "gfx/1.bw.tileset.2bpp"
  .end
Frame2Tiles:
INCBIN "gfx/2.bw.tileset.2bpp"
  .end

BlackTile:
  db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  .end

; -------------------------------------------------------------------------------
SECTION "Tilemap", ROM0

TilemapsTable:
._0 dw Frame1Tilemap
._1 dw Frame2Tilemap

TilemapsSizeTable:
._0 dw Frame1Tilemap.end - Frame1Tilemap
._1 dw Frame2Tilemap.end - Frame2Tilemap

Frame1Tilemap:
INCBIN "gfx/1.bw.tilemap"
  .end
Frame2Tilemap:
INCBIN "gfx/2.bw.tilemap"
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

; Index of the frame being rendered
; (the frame being presented is the previous one)
hFrameIndex: ds 1

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
