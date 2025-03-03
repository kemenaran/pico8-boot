INCLUDE "src/hardware.inc"
INCLUDE "src/pico8.inc"
INCLUDE "src/constants.inc"
INCLUDE "src/options.inc"

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
  ld a, LCDCF_OFF
  ld [rLCDC], a
  xor a ; clear interrupts requests, in order to avoid an immediate VBlank interrupt on the first frame
  ldh [rIF], a

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
  ld de, DefaultAttrmapBG0
  ld hl, _SCRN0
  ld bc, ATTRMAP_HEIGHT
  call CopyAttrmap

  ld de, DefaultAttrmapBG1
  ld hl, _SCRN1
  ld bc, ATTRMAP_HEIGHT
  call CopyAttrmap

  ; Load initial BG palettes
  ld hl, Pico8Palettes
  call CopyBGPalettes

  ; Present the first frame
  call SwapBuffers.presentBufferA

  ; Configure interrupts
  ld a, IEF_VBLANK
  ldh [rIE], a
  ei

  ; Turn the LCD on
  ld a, LCDCF_ON | LCDCF_BGON | LCDCF_BLK01
  ld [rLCDC], a

  ; Start the main loop
  jp MainLoop

MainLoop:
  ; Stop the CPU until the next interrupt
  halt
  nop
  ; Ensure we actually reached v-blank
.ensureVBlank
  ld a, [rLY]
  cp 144
  jr c, .ensureVBlank

  ; If there are still frame data to load, do it.
  call LoadFrameDataIfNeeded

  ; If a new frame is ready, present it.
  ; (And otherwise, the previous frame remains displayed.)
  call PresentFrameIfNeeded

  call SwapBuffersIfReady

  ; Loop
  jr MainLoop

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
  ldh a, [hFrame]
  cp a, c
  jp z, .return

  ; If there are still data to load for this frame, execute the next loading stage.
  ldh a, [hFrameLoaded]
  and a
  jp z, LoadFrameData

.return
  ret

PresentFrameIfNeeded:
  ; If the next frame is still loading, we can't present it yet
  ldh a, [hFrameLoaded]
  and a
  jp z, .return

  ; If no frame has been presented yet, immediately present the first one
  ldh a, [hFrame]
  and a
  jp z, .presentFrame

  ; If the presented frame duration is larger than the intended duration,
  ; time to present the next frame.
  ld hl, AnimationStruct
  call GetPresentedFrameStruct
  call GetFrameDuration ; c = intended duration of the presented frame
  ldh a, [hFrameVICount]
  cp a, c
  jp nz, .return

.presentFrame
  call AnimationFrameReady

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
  ldh [hNeedsPresentingFrame], a
  ldh [hFrameVICount], a
  call IncrementAnimationFrame
  ; fallthrough

; Swap the front buffer and the back buffer (tile data and BG map)
SwapBuffers:
  ld a, [hTilesDataBankFront]
  and a
  jp z, .presentBufferB

.presentBufferA
  ; Tiles data are presented from VRAM bank 0
  xor a
  ld [hTilesDataBankFront], a
  ld a, 1
  ld [hTilesDataBankBack], a
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
  ; Tiles data are presented from VRAM bank 1
  ld a, 1
  ld [hTilesDataBankFront], a
  xor a
  ld [hTilesDataBankBack], a
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

INCLUDE "src/interrupt_vblank.asm"
INCLUDE "src/table_jump.asm"
INCLUDE "src/memory.asm"
INCLUDE "src/gfx.asm"
INCLUDE "src/animation.asm"
INCLUDE "gfx/animation.inc"

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
hVICount: db

; Number of vertical interrupts that occured for the presented frame
hFrameVICount: db

; Index of the animation frame being rendered
; (the frame being presented is the previous one)
hFrame: db

; Index of the loading stage of the animation frame being rendered
hFrameLoadingStage: db

; Address offset for the next tileset chunk to load
hTilesetOffset: dw

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
