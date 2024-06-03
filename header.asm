SECTION "Interrupt VBlank", ROM0[$0040]
  reti

SECTION "Header", ROM0[$100]
  jp EntryPoint

ds $150 - @, 0 ; Make room for the header
