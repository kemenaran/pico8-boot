; Executed by the VBlank interrupt handler
VBlankInterrupt:
  ; Increment the VI counts
  ld hl, hVICount
  inc [hl]
  ld hl, hFrameVICount
  inc [hl]

  reti
