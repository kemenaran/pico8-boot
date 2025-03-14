.PHONY: build
.PRECIOUS: %.2bpp
.DEFAULT_GOAL := build

asm_files = $(shell find . -type f -name '*.asm' -o -name '*.inc')
gfx_files = $(shell find ./gfx -type f -name '*.tileset.png')
bin_files = $(shell find ./gfx -type f -name '*.tilemap')

# Compile a PNG file to a 2BPP file, without any special conversion.
%.2bpp: %.png
	rgbgfx -o $@ $<

# Compile an ASM file into an object file
%.o: %.asm $(asm_files) $(gfx_files:.png=.2bpp) $(bin_files)
	rgbasm --export-all -o $@ $<

# Build the demo ROM
pico8-boot.gbc: main.o
	rgblink -n $(@:.gbc=.sym) -o $@ $^
	rgbfix --color-only --mbc-type MBC5 --pad-value 0xFF --validate $@

# Build a test of palettes swap timing
palettes-test.gbc: palettes-test.o
	rgblink -n $(@:.gbc=.sym) -o $@ $^
	rgbfix --color-only --mbc-type MBC5 --pad-value 0xFF --validate $@

build: pico8-boot.gbc

clean:
	rm -f *.o
	rm -f gfx/*.2bpp
	rm -f pico8-boot.gbc
	rm -f pico8-boot.gbc.sym
	rm -f palettes-test.gbc
	rm -f palettes-test.gbc.sym
