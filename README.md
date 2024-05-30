This code reproduces the pico8 boot animation on a Game boy Color.

Implementation
==============

The boot animation is composed of 6 frames.

Each frames changes the color of many pixels – but the palette itself never changes (it is a fixed set of 32 colors).

To achieve the effect:

- On each line (hblank), the BG tile attributes are DMA-ed to reference the proper colors. There's 16 bytes to transfer.
  _This allows to display 4 colors per 8x1 line (instead of 4 colors per 8x8 block)._
- On each frame (vblank), the BG tile data is updated with the new pixels.


Issues
======

- On the original boot animation, somes 8x1 lines feature 5 differents colors (4 colors + black backround). The GBC is limited to 4 colors per 8x1 line.
- Although we can change the palette or tile attributes on each scanline, each 8x1 line would need to pick one of the 8 available palettes. So all 16 pixels blocks on a line would need to share 8 palettes.

Clues :

- For more colors per 8x1 block: add sprites to work around this
- Use the GBC screen remanence to display more colors
- Change the Y-scroll during scanline rendering, for more color (https://github.com/LIJI32/GBVideoPlayer/blob/master/How%20It%20Works.md)
-

Ressources
==========

Pico 8 palette :
0: #000000
1: #ff004d
2: #7e2553
3: #1d2b53
4: #4f4843
5: #ab5236
6: #83769c
7: #008751
8: #ffa300
9: #29adff
10: #c2c3c7
11: #00e756
12: #ffe727
13: #fff1e8
14: #ffffff
15: #000000

As GBC bytes:
dw $0000
dw $1F24
dw $8F28
dw $A328
dw $2921
dw $5519
dw $D04D
dw $002A
dw $9F02
dw $A57E
dw $1863
dw $802B
dw $9F13
dw $DF77
dw $FF7F
dw $0000


Tools
=====

Palettes converter:
- https://orangeglo.github.io/BGR555/
