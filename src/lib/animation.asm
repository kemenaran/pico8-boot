; ---------------------------------------------------------------------------------
; Routines for manipulating an animated picture, defined as a collection of frames.
;
; Requires: 'table_jump.asm', 'gfx.asm'
; ---------------------------------------------------------------------------------

; Reset the animation variables to zero.
ResetAnimation::
  xor a
  ldh [hFrame], a
  ldh [hFrameLoadingStage], a
  ldh [hTilesetCopyCommand.sourceAddr + 0], a
  ldh [hTilesetCopyCommand.sourceAddr + 1], a
  ldh [hTilemapCopyCommand.sourceAddr + 0], a
  ldh [hTilemapCopyCommand.sourceAddr + 1], a
  ldh [hTilesetOffset + 0], a
  ldh [hTilesetOffset + 1], a
  ldh [hFrameLoaded], a
  ret

; Inputs:
;   hl  address of the animation struct
; Returns:
;   bc  number of frames of the animation
GetAnimationFramesCount::
  ld bc, AnimationStruct.framesCount - AnimationStruct
  add hl, bc
  ld a, [hl]
  ld c, a
  ret

; Retrieve the address of the frame struct for the currently presented frame.
;
; Inputs:
;   hl  address of the animation struct
; Returns:
;   de  address of the presented frame struct
GetPresentedFrameStruct::
  ldh a, [hFrame]
  sub a, 1
  jp  GetFrameStruct

; Retrieve the address of the frame struct for the frame being rendered.
;
; Inputs:
;   hl  address of the animation struct
; Returns:
;   de  address of the rendered frame struct
GetRenderedFrameStruct::
  ldh a, [hFrame]
  ; fallthrough

; Retrieve the address of the frame struct for a given frame.
;
; Inputs:
;   hl  address of the animation struct
;   a   index of the frame to retrieve
; Returns:
;   de  address of the frame struct
GetFrameStruct::
  ; a = (.frames + a * 2)
  sla a
  add a, AnimationStruct.frames - AnimationStruct
  ; bc = 0 + a
  ld  c, a
  xor a
  ld b, a
  add hl, bc
  ; de = frame struct address
  ld a, [hli]
  ld e, a
  ld a, [hl]
  ld d, a
  ret

; Retrieve the intended duration of a frame.
;
; Inputs:
;   de  address of the frame struct
; Returns:
;    c  the duration of the frame
GetFrameDuration::
  push hl

  ld h, d
  ld l, e
  ld bc, Frame0.duration - Frame0
  add hl, bc
  ld c, [hl]

  ; c = c * ANIMATION_SPEED_FACTOR
IF ANIMATION_SPEED_FACTOR > 1
  xor a
REPT ANIMATION_SPEED_FACTOR
  add a, c
ENDR
  ld c, a
ENDC

  pop hl
  ret

; Retrieve the palettes diffs of a frame.
;
; Inputs:
;   de  address of the frame struct
; Returns:
;   hl  address of the palettes diff start
;   b   bank of the palettes diff
;   z   whether the address is 0
GetFramePalettesDiff::
  push de
  ; de = Frame.palettesDiff
  ld h, d
  ld l, e
  ld bc, Frame0.palettesDiff - Frame0
  add hl, bc
  ld a, [hli]
  ld e, a
  ld a, [hli]
  ld d, a
  ; b = Frame.palettesDiffBank
  ld a, [hl]
  ld b, a
  ; hl = de
  ld h, d
  ld l, e
  ; Set the z flag if palettesDiff == $0000
  ld a, h
  or a, l
  ; Cleanup and return
  pop de
  ret

; Inputs:
;   hl  address of the animation struct
; Returns:
;   bc  number of animation frames remaining
;   z   set if the animation reached the last frame
GetRemainingFramesCount::
  call GetAnimationFramesCount
  ldh a, [hFrame]
  sub a, c
  ret

; Load the graphical resources required for an animation frame, in several stages.
;
; Inputs:
;   hFrame             index of the frame to load
;   hFrameLoadingStage frame loading stage
PrepareFrameData::
  ; TODO: optimize (no need for a full jump table here)
  ldh a, [hFrameLoadingStage]
  call TableJump
._00 dw PrepareFrameTileset
._01 dw PrepareFrameTilemap
._02 dw .done
.done
  ret

; Load the tileset required for an animation frame into VRAM
; (in several chunks if needed).
;
; TODO: support more than 2 chunks
;
; Inputs:
;   hFrame              index of the frame to load
;   hTilesetOffset      offset of the tileset chunk to load
PrepareFrameTileset:
  ; de = frame struct address
  ld hl, AnimationStruct
  call GetRenderedFrameStruct

  ; a = tileset data bank
  ld h, d
  ld l, e
  ld bc, Frame0.tilesetAddress - Frame0
  add hl, bc

  ;
  ; Fill hTilesetCopyCommand with the proper parameters
  ;

DEF BYTES_PER_TILE = 16
DEF TILES_PER_CHUNK = 128
DEF OFFSET_PER_CHUNK = BYTES_PER_TILE * TILES_PER_CHUNK

  ; source address
  ld a, [hli] ; Frame.tilesetAddress low
  ld e, a
  ld a, [hli] ; Frame.tilesetAddress high
  ld d, a
  push hl ; save the animation frame address
  ; (source += hTilesetOffset)
  ld hl, hTilesetOffset
  ld a, [hli]
  ld h, [hl]
  ld l, a
  add hl, de
  ; (set source address)
  ld a, l
  ldh [hTilesetCopyCommand + 0], a
  ld a, h
  ldh [hTilesetCopyCommand + 1], a
  pop hl ; restore the animation frame address

  ; source bank
  ld a, [hli] ; Frame.tilesetBank
  ldh [hTilesetCopyCommand + 2], a

  ; dest address
  push hl ; save the animation frame address
  ld de, _VRAM
  ; (dest += hTilesetOffset)
  ld hl, hTilesetOffset
  ld a, [hli]
  ld h, [hl]
  ld l, a
  add hl, de
  ; (set dest address)
  ld a, l
  ldh [hTilesetCopyCommand + 3], a
  ld a, h
  ldh [hTilesetCopyCommand + 4], a
  pop hl ; restore the animation frame address

  ; tiles count
  ld a, [hl] ; Frame.tilesetCount
  ld b, 0
  ld c, a
  push bc ; save tilesetCount to the stack
  ; if tilesetCount < TILES_PER_CHUNK, tilesCount = tilesetCount
  cp a, TILES_PER_CHUNK
  jr c, .setTilesCount
  ; else if chunk 0, tilesCount = TILES_PER_CHUNK
  ldh a, [hTilesetOffset + 0]
  and a
  ldh a, [hTilesetOffset + 1]
  and a
  jr nz, .secondChunk
  ld a, TILES_PER_CHUNK
  jr .setTilesCount
  ; else tilesCount = tilesetCount - TILES_PER_CHUNK
.secondChunk
  ld a, c
  sub a, TILES_PER_CHUNK
  ; fallthrough
.setTilesCount
  ldh [hTilesetCopyCommand + 5], a

.commandReady
  ; The copy command is now prepared to be executed during the next vblank.

  ; If the tileset is smaller than a single chunk, we're done.
  pop bc ; pop tilesetCount from the stack
  ld a, c
  cp a, TILES_PER_CHUNK
  jr c, .tilesetDone ; if TILES_PER_CHUNK > a
  ; else if we just copied the second chunk, we're also done.
  ldh a, [hTilesetOffset + 0]
  and a
  ldh a, [hTilesetOffset + 1]
  and a
  jp nz, .tilesetDone
  ; else we just finished the first chunk out of two:
.chunkDone
  ; Increment hTilesetOffset
  ; (hl = [hTilesetOffset])
  ld hl, hTilesetOffset
  ld a, [hli]
  ld h, [hl]
  ld l, a
  ; (hl += OFFSET_PER_CHUNK)
  ld de, OFFSET_PER_CHUNK
  add hl, de
  ; ([hTilesetOffset] = hl)
  ld a, l
  ldh [hTilesetOffset + 0], a
  ld a, h
  ldh [hTilesetOffset + 1], a
  jr .return

.tilesetDone
  ; Cleanup and move to the next stage
  xor a
  ldh [hTilesetOffset + 0], a
  ldh [hTilesetOffset + 1], a
  ld hl, hFrameLoadingStage
  inc [hl]

.return
  ret

; Load the tilemap required for an animation frame into VRAM.
;
; Caveats:
;  - The tilemap is assumed to always be the same size (TILEMAP_WIDTH * TILEMAP_HEIGHT)
;
; Inputs:
;   hFrame  index of the frame to load
PrepareFrameTilemap:
  ; de = frame struct address
  ld hl, AnimationStruct
  call GetRenderedFrameStruct

  ;
  ; Fill hTilemapCopyCommand with the proper parameters
  ;

  ; source address
  ld h, d
  ld l, e
  ld bc, Frame0.tilemapAddress - Frame0
  add hl, bc
  ld a, [hli]
  ldh [hTilemapCopyCommand.sourceAddr + 0], a
  ld a, [hli]
  ldh [hTilemapCopyCommand.sourceAddr + 1], a

  ; source bank
  ld a, [hli]
  ldh [hTilemapCopyCommand.sourceBank], a

  ; destination
  ld a, TILEMAP_TOP * 32 + TILEMAP_LEFT
  ldh [hTilemapCopyCommand.destAddr + 0], a
  ld a, [hBGMapAddressBack]
  ldh [hTilemapCopyCommand.destAddr + 1], a

  ; rows count
  ld a, TILEMAP_HEIGHT
  ldh [hTilemapCopyCommand.rowsCount], a

.commandReady
  ; The copy command is now prepared to be executed during the next vblank.

  ; Move to the next stage
  ld hl, hFrameLoadingStage
  inc [hl]

  ret

CopyFrameData::
  ; If hTilesetCopyCommand.sourceAddr has a non-zero value, copy the tileset
  ld hl, hTilesetCopyCommand.sourceAddr
  ld a, [hli]
  or a, [hl]
  jr nz, ExecuteTilesetCopyCommand

  ; Else if hTilemapCopyCommand.sourceAddr has a non-zero value, copy the tilemap
  ld hl, hTilemapCopyCommand.sourceAddr
  ld a, [hli]
  or a, [hl]
  jr nz, ExecuteTilemapCopyCommand

  ; Nothing to copy: mark the frame as loaded
  ld a, 1
  ldh [hFrameLoaded], a
  ret

ExecuteTilesetCopyCommand:
  ; Switch to back-buffer VRAM bank
  ld a, [hTilesDataBankBack]
  ld [rVBK], a

  ; Copy the tileset chunk
  ld hl, hTilesetCopyCommand
  call CopyTileset

  ; Restore front-buffer VRAM bank
  ld a, [hTilesDataBankFront]
  ld [rVBK], a

  ; Mark the tileset as loaded
  xor a
  ldh [hTilesetCopyCommand.sourceAddr + 0], a
  ldh [hTilesetCopyCommand.sourceAddr + 1], a

  ret

ExecuteTilemapCopyCommand:
  ; Extra: load a single black tile at the end of the tileset
  call LoadReferenceBlackTile

  ; Switch the destination VRAM bank to the tilemap data bank (bank 0)
  xor a
  ld [rVBK], a

  ; Execute the copy command
  ld hl, hTilemapCopyCommand
  call CopyTilemap

  ; Restore the VRAM bank
  ld a, [hTilesDataBankFront]
  ld [rVBK], a

  ; Mark the tilemap as loaded
  xor a
  ldh [hTilemapCopyCommand.sourceAddr + 0], a
  ldh [hTilemapCopyCommand.sourceAddr + 1], a

  ret

; Load a single black tile at the end of the tileset (index $FF)
LoadReferenceBlackTile:
  ; Save the current ROM bank
  ld a, [rROMB0]
  push af
  ; Set the VRAM and ROM banks
  ld a, [hTilesDataBankBack]
  ld [rVBK], a
  ld a, BANK(BlackTile)
  ld [rROMB0], a
  ; Configure the copy
  ld hl, BlackTile
  ld de, _VRAM + $1000 - 16 ; last tile of tiles data memory
  ld bc, 16
  ; Copy the tile
  call CopyData
  ; Restore the VRAM and ROM banks
  ld a, [hTilesDataBankFront]
  ld [rVBK], a
  pop af
  ld [rROMB0], a
  ret

; Load the BG palette required for an animation frame into VRAM,
; then mark the frame as loaded.
;
; The color palette isn't double-buffered: once the palette is loaded,
; the frame needs to be presented immediately to avoid glitches.
;
; Inputs:
;   hFrame  index of the frame to load
LoadFramePalette:
  ; de = frame struct address
  ld hl, AnimationStruct
  call GetRenderedFrameStruct

  ; hl = pointer to palettesAddress
  ld h, d
  ld l, e
  ld bc, Frame0.palettesAddress - Frame0
  add hl, bc

  ; de = palettes sourde address
  ld a, [hli]
  ld e, a
  ld a, [hli]
  ld d, a

  ; Switch the source ROM bank to the palettes bank
  ld a, [hl]
  ld [rROMB0], a

  ; Copy the 8 BG palettes to VRAM
  ld h, d
  ld l, e
  call CopyBGPalettes

  ret
