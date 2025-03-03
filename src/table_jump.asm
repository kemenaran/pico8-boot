; Jump to the routine defined at the given index in the jump table.
;
; Usage:
;   ld   a, <routine_index>
;   rst  0
;   dw   Func_0E00 ; jump address for index 0
;   dw   Func_0F00 ; jump address for index 1
;   ...
;
; Input:
;   a:  index of the routine address in the jump table
TableJump::
    ; de = a
    ld   e, a
    ld   d, 0
    ; Load target adress into hl
    pop  hl
    add  hl, de  ; Add the base address and the offset * 2
    add  hl, de
    ld a, [hli] ; Load the low byte of the target address
    ld h, [hl]  ; Load the high byte of the target address
    ld l, a
    ; Jump to the target address
    jp hl
