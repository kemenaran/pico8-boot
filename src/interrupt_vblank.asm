; Executed by the VBlank interrupt handler
VBlankInterrupt:
  ; Save the registers to the stack
  push af
  push bc
  push de
  push hl

  ; Increment the VI counts
  ld hl, hVICount
  inc [hl]
  ld hl, hFrameVICount
  inc [hl]

  ; If a copy command is ready, execute it.
  call CopyFrameData

  ; If a new frame is ready, present it.
  ; (And otherwise, the previous frame remains displayed.)
  call PresentFrameIfNeeded
  call SwapBuffersIfReady

  ld a, 1
  ldh [hVBlankInterruptServiced], a

  ; Restore the registers from the stack
  pop hl
  pop de
  pop bc
  pop af
  reti

PresentFrameIfNeeded:
  ; If we reached the final frame of the animation, there is nothing to do.
  ld hl, AnimationStruct
  call GetRemainingFramesCount
  jr z, .return

  ; If the next frame is still loading, we can't present it yet
  ldh a, [hFrameLoaded]
  and a
  jr z, .return

  ; If no frame has been presented yet, immediately present the first one
  ldh a, [hFrame]
  and a
  jr z, .presentFrame

  ; If the presented frame duration is larger than the intended duration,
  ; time to present the next frame.
  ld hl, AnimationStruct
  call GetPresentedFrameStruct
  call GetFrameDuration ; c = intended duration of the presented frame
  ldh a, [hFrameVICount]
  cp a, c
  jr c, .return ; skip presenting the frame if hFrameVICount > intended frame duration

.presentFrame
  ; The color palette isn't double-buffered: we need to load it right before presenting the frame.
  call LoadFramePalette
  call AnimationFrameReady

.return
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
  D_LOG "Swapping buffers (front: bank 0; back: bank 1)"
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
  D_LOG "Swapping buffers (front: bank 1; back: bank 0)"
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
