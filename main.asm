; From https://gbdev.io/gb-asm-tutorial/part1/hello_world.html

INCLUDE "hardware.inc"
INCLUDE "header.asm"
INCLUDE "table_jump.asm"
INCLUDE "memory.asm"

; Tilemap layout, in tiles
DEF TILEMAP_WIDTH EQU 16
DEF TILEMAP_TOP   EQU 1
DEF TILEMAP_LEFT  EQU 2

; Number of frames in the animation
DEF MAX_ANIMATION_FRAMES EQU 2

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

  ; Clear memory
  call ClearHRAM

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

  ; Load the first frame
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

  ; Start the render loop
  jp MainLoop.swapBuffers

MainLoop:
  ; Stop the CPU until the next interrupt
  halt
  nop
  ; Ensure we actually reached v-blank
.ensureVBlank
  ld a, [rLY]
  cp 144
  jp c, .ensureVBlank

  ; Increment the VI count
  ld hl, hVICount
  inc [hl]

  ; Load the next data (this might or might not result in a new frame being ready)
  call ExecuteDataLoading

  ; If the new frame is ready, swap buffers
  ld a, [hNeedsPresentingFrame]
  and a
  jp z, .swapBuffersEnd
.swapBuffers
  xor a
  ld [hNeedsPresentingFrame], a
  call SwapBuffers
.swapBuffersEnd

  ; Loop
  jp MainLoop

; Execute a data-loading step on each VBlank.
;
; The data-loading step may result in a new frame being ready to be presented,
; or require additional loading steps during the next VBlank.
;
; This function must not execute longer than the VBlank duration.
ExecuteDataLoading:
  ; If we reached the last animation frame, return
  ld a, [hFrameIndex]
  cp MAX_ANIMATION_FRAMES - 1
  jp z, MainLoop

  ; Execute the handler for the current VI
  ld a, [hVICount]
  call TableJump
._0 dw LoadFrame0
._1 dw LoadFrame1Tileset
._2 dw LoadFrame1Tilemap
._3 dw LoadFrame2
; todo: add other frames

; Frame 0 loads while the screen is turned off.
; It can be loaded in one go.
LoadFrame0:
  xor a
  ld [hFrameIndex], a

  call CopyFrameTileset
  call CopyBlackTile
  call CopyFrameTilemap
  ld a, 1
  ld [hNeedsPresentingFrame], a
  ret

LoadFrame1Tileset:
  ld hl, hFrameIndex
  inc hl

  call CopyFrameTileset
  ret

LoadFrame1Tilemap:
  call CopyBlackTile
  call CopyFrameTilemap

  ld a, 1
  ld [hNeedsPresentingFrame], a
  ret

LoadFrame2:
  ld hl, hFrameIndex
  inc hl
  ; TODO
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
  ; Switch to VRAM bank 0
  xor a
  ld [rVBK], a
  ; Copy
  call CopyTilemap
  ; Restore front VRAM bank
  ld a, [hTilesDataBankFront]
  ld [rVBK], a
  ret

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
  ld de, $8000 + $1000 - 16
  ; bc = size
  ld bc, BlackTile.end - BlackTile
  ; Switch to back VRAM bank
  ld a, [hTilesDataBankBack]
  ld [rVBK], a
  ; Copy
  call CopyData
  ; Restore front VRAM bank
  ld a, [hTilesDataBankFront]
  ld [rVBK], a
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

; Number of vertical interrupts that occured
hVICount: ds 1

; Index of the animation frame being rendered
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
