INCLUDE "src/options.inc"

INCLUDE "src/include/hardware.inc"
INCLUDE "src/include/pico8.inc"
INCLUDE "src/include/constants.inc"
INCLUDE "src/include/debug.inc"

SECTION "VBlank interrupt", ROM0[INT_HANDLER_VBLANK]
  jp VBlankInterrupt

SECTION "STAT Interrupt", ROM0[INT_HANDLER_STAT]
  jp STATInterrupt

SECTION "Header", ROM0[$100]
  jp Init

ds $150 - @, 0 ; Make room for the header

Init:
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

  D_LOG "Start"

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
  ld hl, BlackPalettes
  call CopyBGPalettes

  ; Present the first frame
  call SwapBuffers.presentBufferA

  ; Configure interrupts
  ld a, STATF_LYC ; configure the STAT interrupt to enable LY-compare
  ldh [rSTAT], a
  ld a, IMAGE_FIRST_SCANLINE - 1 ; fire the STAT interrupt just before the first scanline of the image
  ldh [rLYC], a
  ld a, IEF_VBLANK | IEF_STAT ; enable VBlank and STAT interrupts
  ldh [rIE], a
  ei

  ; Turn the LCD on
  ld a, LCDCF_ON | LCDCF_BGON | LCDCF_BLK01
  ld [rLCDC], a

  ; Start the main loop
  jp MainLoop

MainLoop:
  call HandleInputs

  ; If we reached the final frame of the animation, nothing to do.
  ld hl, AnimationStruct
  call GetRemainingFramesCount
  jr z, .waitForVBlank

  ; If the frame is already loaded (and just waiting for display), nothing to do.
  ldh a, [hFrameLoaded]
  and a
  jp nz, .waitForVBlank

  ; Prepare a copy command to be executed during the next vblank interval.
  call PrepareFrameData

.waitForVBlank
  ; Stop the CPU until the next interrupt
  halt
  nop
  ; Ensure we actually reached vblank
  ldh a, [hVBlankInterruptServiced]
  and a
  jr z, .waitForVBlank
  xor a
  ldh [hVBlankInterruptServiced], a

  ; Loop
  jr MainLoop

; Process pressed joypad keys.
;
; The available keys are:
; - pressing any button once the animation ended: restart the animation
HandleInputs:
IF DEBUG >= 0
  ld hl, AnimationStruct
  call GetAnimationFramesCount
  ldh a, [hFrame]
  cp a, c
  D_ASSERT_Z "Reading inputs should only be executed once the animation ended"
ENDC

  ; Update pressed keys state
  call UpdateKeys

  ; If any key is pressed…
  ld a, [wCurKeys]
  and a
  jr z, .anyKeyEnd
  ; …restart the animation.
  ld hl, BlackPalettes
  call CopyBGPalettes
  call ResetAnimation
.anyKeyEnd

  ret

INCLUDE "src/interrupt_vblank.asm"
INCLUDE "src/interrupt_stat.asm"
INCLUDE "src/lib/table_jump.asm"
INCLUDE "src/lib/memory.asm"
INCLUDE "src/lib/gfx.asm"
INCLUDE "src/lib/animation.asm"
INCLUDE "src/lib/joypad.asm"
INCLUDE "gfx/animation.inc"

; -------------------------------------------------------------------------------
SECTION "WRAM Stack", WRAM0[$CE00]

; Bottom of WRAM is used as the stack
wStack::
  ds $CFFF - @ + 1

; Init puts the SP here
DEF wStackTop EQU $CFFF

; -------------------------------------------------------------------------------
SECTION "Input Variables", WRAM0

; Joypad keys currently pressed (see UpdateKeys)
wCurKeys: db

; Joypad keys that were newly pressed (see UpdateKeys)
wNewKeys: db


; -------------------------------------------------------------------------------
SECTION "HRAM", HRAM[$FF80]

; Whether the V-Blank interrupt has been executed during this iteration of the main loop
hVBlankInterruptServiced: db

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

; Scratchpad structure used by CopyTilemap
hTilemapCopyCommand:
.sourceAddr dw
.sourceBank db
.destAddr   dw
.rowsCount  db

; Whether the next frame resources are loaded
hFrameLoaded: db

; Whether the next frame should be presented at the next vblank
hNeedsPresentingFrame: db

; VRAM bank for tiles data currently presented (0 or 1)
hTilesDataBankFront: db
; VRAM bank for tiles data currently rendered into (0 or 1)
hTilesDataBankBack: db

; High-byte of the BG map area currently presented
hBGMapAddressFront: db
; High-byte of the BG map area currently rendered into
hBGMapAddressBack: db

; Original address of the stack pointer
; (sp gets modified during the interrupt popslide.)
hStackPointer: dw
