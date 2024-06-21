; From https://gbdev.io/gb-asm-tutorial/part1/hello_world.html

INCLUDE "hardware.inc"
INCLUDE "constants.asm"

DEF PALETTE_SWAP_START_VI EQU 30

SECTION "Interrupt VBlank", ROM0[$0040]
  jp VBlankInterrupt

SECTION "LCD Status interrupt", ROM0[$0048]
  jp ScanlineInterrupt

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

  ; Clear attributes map
  ld de, _SCRN0
  ld bc, _SRAM - _SCRN0
  ld a, $00 ; use BG palette 0
  call FillData

  ; Load a fully black BG palettes set
  ld hl, BlackPalettes
  call CopyBGPalettes

  ; Load a black tile
  call CopyBlackTile

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

  ; If we reached the demo start, enable the palette swap code
  ld a, [hVICount]
  cp PALETTE_SWAP_START_VI
  jp z, .enableScanlineInterrupt
  ; One frame after, disable the palette swap code
  cp PALETTE_SWAP_START_VI + 1
  jp z, .disableScanlineInterrupt
  jp .done

.enableScanlineInterrupt
  ; Trigger the scanline interrupt on mode 0 (HBlank)
  ; TODO: trigger on mode 2 instead (OAM scan), to have more time for swapping palettes
  ld a, STATF_MODE00
  ldh [rSTAT], a
  ; Enable the scanline interrupt
  ld a, IEF_VBLANK | IEF_STAT
  ldh [rIE], a
  jp .done

.disableScanlineInterrupt
  ld a, IEF_VBLANK
  ldh [rIE], a

.done
  reti

ScanlineInterrupt:
  reti

CopyBlackTile:
  ld hl, BlackTile
  ld de, _VRAM + $0FF0
  ld bc, BlackTile.end - BlackTile
  jp CopyData

INCLUDE "memory.asm"
INCLUDE "gfx.asm"

; -------------------------------------------------------------------------------
SECTION "Tilesets - frame 1-4", ROMX, BANK[$01]

ALIGN 4 ; Align to 16-bytes boundaries, for HDMA transfer
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
