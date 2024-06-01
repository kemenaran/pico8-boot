.PHONY: default build run
.PRECIOUS: %.2bpp

asm_files = $(shell find . -type f -name '*.asm' -o -name '*.inc')
gfx_files = $(shell find ./gfx -type f -name '*.png')

# Compile a PNG file to a 2BPP file, without any special conversion.
%.2bpp: %.png
	rgbgfx -o $@ $<

# Compile an ASM file into an object file
%.o: %.asm $(asm_files) $(gfx_files:.png=.2bpp)
	rgbasm --export-all --halt-without-nop --preserve-ld -o $@ $<

pico8-boot.gbc: main.o
	rgblink -n $(@:.gbc=.sym) -o $@ $^
	rgbfix --color-only --mbc-type MBC5 --pad-value 0xFF --validate $@

build: pico8-boot.gbc

clean:
	rm -f *.o
	rm -f gfx/*.2bpp
	rm -f pico8-boot.gbc.sym
	rm -f pico8-boot.gbc

default: build
