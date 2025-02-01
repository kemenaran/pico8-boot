; From https://gbdev.io/gb-asm-tutorial/part1/hello_world.html

INCLUDE "hardware.inc"
INCLUDE "pico8.inc"
INCLUDE "constants.inc"

SECTION "Interrupt VBlank", ROM0[$0040]
  jp VBlankInterrupt

SECTION "Header", ROM0[$100]
  jp EntryPoint

ds $150 - @, 0 ; Make room for the header

EntryPoint:
  ; Shut down audio circuitry
  ld a, 0
  ld [rNR52], a

  ; Turn the LCD off
  ; (do not turn the LCD off outside of VBlank)
.waitVBlank
  ld a, [rLY]
  cp 144
  jr c, .waitVBlank
  ld a, 0
  ld [rLCDC], a

  ; Switch CPU to double-speed
  xor  a
  ldh  [rIE], a
  ld   a, P1F_5 | P1F_4
  ldh  [rP1], a
  ld   a, KEY1F_PREPARE
  ldh  [rKEY1], a
  stop

  ; Initialize stack
  ld sp, wStackTop

  ; Clear HRAM
  ld hl, _HRAM
  ld bc, $FFFE - _HRAM
  call ClearData

  ; Clear BG maps
  call ClearBGMap0
  call ClearBGMap1

  ; Load initial tileset
  ; (i.e. a single black tile as tile n° $FF)
  ld hl, BlackTile
  ld de, _VRAM + $1000 - 16 ; last tile of tiles data memory
  ld bc, 16
  call CopyData

  ; Load initial attmaps
  ld de, DefaultAttrmap
  ld hl, _SCRN0
  ld bc, ATTRMAP_HEIGHT
  call CopyAttrmap

  ld de, DefaultAttrmap
  ld hl, _SCRN1
  ld bc, ATTRMAP_HEIGHT
  call CopyAttrmap

  ; Initialize double-buffering
  ; (first frame will be written to VRAM bank 0)
  call SwapBuffers.init

  ; Load a fully black screen for the first frame
  xor a
  ldh [hFrame], a
  call LoadFrameData

  ; Present the first frame
  call SwapBuffers
  call IncrementAnimationFrame

  ; Turn the LCD on
  ld a, LCDCF_ON | LCDCF_BGON | LCDCF_BLK01
  ld [rLCDC], a

  ; During the first (blank) frame, initialize the DMG palette
  ; TODO: is this required on GBC?
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

  ; If there are still frame data to load, do it.
  call LoadFrameDataIfNeeded

  ; If a new frame is ready, present it.
  ; (And otherwise, the previous frame remains displayed.)
  call PresentFrameIfNeeded
  reti

; Execute a data-loading step on each VBlank.
;
; The data-loading step may result in a new frame being ready to be presented,
; or require additional loading steps during the next VBlank.
;
; This function must not execute longer than the VBlank duration.
LoadFrameDataIfNeeded:
  ; If we reached the last animation frame, return early.
  ld hl, AnimationStruct
  call GetAnimationFramesCount
  ld a, [hFrame]
  cp a, c
  jp z, .return

  ; If there are still data to load for this frame, execute the next loading stage.
  ldh a, [hFrameLoaded]
  jp z, LoadFrameData

.return
  ret

PresentFrameIfNeeded:
  ; If the next frame is still loading, we can't present it yet
  ldh a, [hFrameLoaded]
  jp z, .return

  ; bc = intended duration of the presented frame
  ld hl, AnimationStruct
  call GetPresentedFrameStruct
  call GetFrameDuration

  ; If the current frame duration is larger than the intended duration,
  ; time to present the next frame.
  ldh a, [hFrameVICount]
  cp a, c
  call z, AnimationFrameReady

.return
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
  ; Reset the loading state
  xor a
  ld [hFrameLoaded], a
  ld [hFrameLoadingStage], a
  ret

SwapBuffersIfReady:
  ; If no new frame is ready, present the same buffer
  ld a, [hNeedsPresentingFrame]
  and a
  ret z

  ; Swap buffers
  xor a
  ld [hNeedsPresentingFrame], a
  ld [hFrameVICount], a
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

.init
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
INCLUDE "animation.asm"

; -------------------------------------------------------------------------------
; Animated picture definition

AnimationStruct:
.framesCount
  db 2
.frames
  dw Frame0
  dw Frame1

Frame0:
.duration       db 6
.tilesetBank    db BANK(Frame0Tiles)
.tilesetAddress dw Frame0Tiles
.tilesetCount   dw (Frame0Tiles.end - Frame0Tiles / 16)
.tilemapBank    db BANK(Frame0Tilemap)
.tilemapAddress dw Frame0Tilemap

Frame1:
.duration       db 6
.tilesetBank    db BANK(Frame1Tiles)
.tilesetAddress dw Frame1Tiles
.tilesetCount   dw (Frame1Tiles.end - Frame1Tiles) / 16
.tilemapBank    db BANK(Frame1Tilemap)
.tilemapAddress dw Frame1Tilemap

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

DefaultAttrmap:
  ; First row
  ds ATTRMAP_WIDTH, $07
  ; Colored rows
  REPT 16
  ds ATTRMAP_WIDTH, $00, $01, $02, $03, $04, $05, $06, $07
  ENDR
  ; Last row
  ds ATTRMAP_WIDTH, $07
.end

; -------------------------------------------------------------------------------
SECTION "Tilesets - frame 1-4", ROMX, BANK[$01]

ds align[4] ; Align to 16-bytes boundaries, for HDMA transfer
BlackTile:
  db 16, $FF
.end

ds align[4]
Frame0Tiles:
  db 16, $FF
.end

ds align[4]
Frame1Tiles:
  INCBIN "gfx/1.bw.tileset.2bpp"
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

; Total number of vertical interrupts that occured since the beginning
hVICount: ds 1

; Number of vertical interrupts that occured for the presented frame
hFrameVICount: ds 1

; Index of the animation frame being rendered
; (the frame being presented is the previous one)
hFrame: ds 1

; Index of the loading stage of the animation frame being rendered
hFrameLoadingStage: ds 1

; Index of the next tileset chunk to load
hTilesetLoadingStage: ds 1

; Scratchpad structure used by CopyTileset
hTilesetCopyCommand:
.sourceAddr dw
.sourceBank db
.destAddr   dw
.tilesCount db

; Whether the next frame resources are loaded
hFrameLoaded: ds 1

; Whether the next frame should be presented at the next vblank
hNeedsPresentingFrame: ds 1

; VRAM bank for tiles data currently presented (0 or 1)
hTilesDataBankFront: ds 1
; VRAM bank for tiles data currently rendered into (0 or 1)
hTilesDataBankBack: ds 1

; High-byte of the BG map area currently presented
hBGMapAddressFront: ds 1
; High-byte of the BG map area currently rendered into
hBGMapAddressBack: ds 1
