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

- It takes a while to load the tileset and tilemap.
 If needed, we can HDMA them during HBlank (one tile per scanline)

- On the original boot animation, somes 8x1 lines feature 5 differents colors (4 colors + black backround). The GBC is limited to 4 colors per 8x1 line
- Although we can change the palette or tile attributes on each scanline, each 8x1 line would need to pick one of the 8 available palettes. So all 16 pixels blocks on a line would need to share 8 palettes.

Hardware infos:
- We can change up to 23 colors per scanline (maybe more if we skip black)
- 8 palettes of 3 colors + black is 24 colors.
- So we can change almost all colors during H-blank

Clues :

- For more colors per 8x1 block: add sprites to work around this
- Use the GBC screen remanence to display more colors
- Change the Y-scroll during scanline rendering, for more color (https://github.com/LIJI32/GBVideoPlayer/blob/master/How%20It%20Works.md)

Transforming the original image:
1. Copy the first column of pixels to the last, to restore symetry    ;
2. Translate the image by 1px, for tiles to be aligned to a 8x8 grid  ; both reduce cases of 5 colors per 8x1 to 4
3. Crop half of the image, and duplicate it on render (reduce number of palettes per scanline from max 16 to max 8)
4. TODO: Rotate the original artwork by 1px every line, and back-correct by changing the X-scroll of 1px during HBLANK (see if it helps to reduce the line-by-line diff)

Tools
=====

Palettes converter:
- https://orangeglo.github.io/BGR555/ (use Big Endian)

Images conversion:
- `convert 1.small.png +dither -colorspace Gray -colors 4 -depth 4 1.bw.png`
- `rgbgfx original-gfx/4-colors/1.bw.png --unique-tiles --tilemap gfx/1.bw.tilemap --output gfx/1.bw.tileset.2bpp`
- `rgbgfx gfx/3.bw.tileset.png --reverse 16 --output gfx/3.bw.tileset.2bpp`

Changing palettes mid-scanline demos:
https://github.com/EmmaEwert/gameboy
https://noncircadian.tumblr.com/post/162989007715/2-bits-per-pixel

TODO
====

- ✅ Display the first frame in DMG mode
- ✅ Implement double-buffering
- ✅ Switch to DMG-on-GBC (but with double speed)
- ✅ Why aren't the second frame tiles written to VRAM bank 1?
 (Because we're not in CGB compatible mode!)
- ✅ Convert the ROM to GBC
- ✅ Split loading into several stages (it seems 224 tiles can be loaded per vblank max)
- ✅ DMA tiles and tilemap
  - ✅ Align tilesets to $10 boundaries
  - ✅ Optimize tilemap load to fit a VBlank period
  - ✅ DMA only the allowed size (split large tilesets in two)
  - ✅ Rewrite tileset datastructures as structs (instead of several arrays)
- ✅ First frame is black
- ✅ Diplay all frames in non-colored mode
- ✅ Add basic colors
- ✅ Fix order of data loading and buffer swap (to avoid a flash of colors)
- Color-correct the pico8 colors
- ✅ Write a script to output color statistics about an image: color count per picture/per tile/per 8x2 bloc
- ✅ Write a script to rotate the image by 1px every line, and see if the stats are better
- Code a demo to see how many colors can be updated every scanline
- Write a script to output a new image with reduced colors and/or tiles that can be displayed by the GBA

