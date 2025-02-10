; Divide hl by c.
;
; Inputs:
;   hl   dividend
;   c    divisor
; Returns:
;   hl   quotient
;   a    remainder
div_hl_c::
  xor  a
  ld b, 16

.loop
   add  hl, hl
   rla
   jr c, $+5
   cp c
   jr c, $+4

   sub  c
   inc  l

   jp nz .loop

   ret
