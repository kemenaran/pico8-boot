; ---------------------------------------------------------------------------------
; Routines for manipulating an animated picture, defined as a collection of frames.
;
; Requires: 'table_jump.asm', 'gfx.asm'
; ---------------------------------------------------------------------------------

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

  pop hl
  ret

; Load the graphical resources required for an animation frame, in several stages.
;
; Inputs:
;   hFrame             index of the frame to load
;   hFrameLoadingStage frame loading stage
LoadFrameData::
  ldh a, [hFrameLoadingStage]
  call TableJump
  dw LoadFrameTileset
  dw LoadFrameTilemap
  dw LoadFramePalette
  dw .done ; should never be reached

.done
  ; Mark the frame as loaded
  ld a, 1
  ldh [hFrameLoaded], a
  ret

; Load the tileset required for an animation frame into VRAM
; (in several chunks if needed).
;
; Inputs:
;   hFrame               index of the frame to load
;   hTilesetLoadingStage index of the tileset chunk to load
LoadFrameTileset:
  ; de = frame struct address
  ld hl, AnimationStruct
  call GetRenderedFrameStruct

  ; a = tileset data bank
  ld h, d
  ld l, e
  ld bc, Frame0.tilesetBank - Frame0
  add hl, bc
  ld a, [hli]

  ; Switch the source ROM bank to the tileset data bank
  ld [rROMB0], a

  ; Fill hTilesetCopyCommand with the proper parameters
  ; source address
  ld a, [hli]
  ldh [hTilesetCopyCommand + 0], a
  ld a, [hli]
  ldh [hTilesetCopyCommand + 1], a
  ; dest address
  ; FIXME: allow loading in several chunks
  ld a, LOW(_VRAM)
  ldh [hTilesetCopyCommand + 2], a
  ld a, HIGH(_VRAM)
  ldh [hTilesetCopyCommand + 3], a
  ; tiles count
  ; FIXME: allow loading in several chunks
  ld a, [hli]
  ldh [hTilesetCopyCommand + 4], a

  ; Switch to back-buffer VRAM bank
  ld a, [hTilesDataBankBack]
  ld [rVBK], a

  ; Copy
  ld hl, hTilesetCopyCommand
  call CopyTileset

  ; Restore front-buffer VRAM bank
  ld a, [hTilesDataBankFront]
  ld [rVBK], a

.done
  ld hl, hFrameLoadingStage
  inc hl
  ret

; Load the tilemap required for an animation frame into VRAM.
;
; Caveats:
;  - The tilemap is assumed to always be the same size (TILEMAP_WIDTH * TILEMAP_HEIGHT)
;
; Inputs:
;   hFrame  index of the frame to load
LoadFrameTilemap:
  ; de = frame struct address
  ld hl, AnimationStruct
  call GetRenderedFrameStruct

  ; a = tilemap data bank
  ld h, d
  ld l, e
  ld bc, Frame0.tilemapBank - Frame0
  add hl, bc
  ld a, [hli]

  ; Switch the source ROM bank to the tilemap data bank
  ld [rROMB0], a

  ; de = source address
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

  ; Switch the destination VRAM bank to the tilemap data bank (bank 0)
  xor a
  ld [rVBK], a

  ; Copy
  call CopyTilemap

  ; Restore the VRAM bank
  ld a, [hTilesDataBankFront]
  ld [rVBK], a

.done
  ld hl, hFrameLoadingStage
  inc hl
  ret

; Load the BG palette required for an animation frame into VRAM,
; then mark the frame as loaded.
;
; Inputs:
;   hFrame  index of the frame to load
LoadFramePalette:
  ; TODO: load palette

.done
  ld hl, hFrameLoadingStage
  inc hl
  jp LoadFrameData.done
