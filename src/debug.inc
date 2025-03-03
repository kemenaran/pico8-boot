IF DEBUG <= 0

; In release mode, stub out debug macros
MACRO D_LOG
ENDM
MACRO D_BREAK
ENDM

ELSE ; DEBUG > 0

; Log a message to the no$gmb / bgb debugger.
; Accepts a string as input.
MACRO D_LOG
  ld  d, d
  jr .end\@
  dw $6464
  dw $0000
  db \1
.end\@:
ENDM

; Set a source breakpoint for the no$gmb / bgb debugger.
MACRO D_BREAK
  ld b, b
ENDM

ENDC
