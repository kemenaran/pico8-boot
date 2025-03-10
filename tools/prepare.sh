#!/bin/bash -euxo pipefail
#
# Prepare an image for rendering by the main GBC executable:
# - Indexation by palettes
# - Palettes sequence generation
# - Shift
# - Tileset and tilemap generation
#
# Usage:
#   tools/prepare.sh 4

NAME="$1" # image name (minus the extension)

# Rotate the original image, to align similar colors on the same column
tools/pngshift.rb "original-gfx/${NAME}.png" "original-gfx/shifted/${NAME}.png"

# Generate the indexed PNG and palettes scanline diffs
tools/encode.rb "original-gfx/shifted/${NAME}.png" --palette-fixed-colors-alternated --output-palettes "gfx/${NAME}.palettes.asm" --output-png "gfx/${NAME}.png"

# Add a black mask on the left and right of the image, to display a border around the picture
tools/pngmask.rb --palette-fixed-colors-alternated --repeat 2 "gfx/${NAME}.png" "gfx/${NAME}.masked.png"

# Generate a 2bpp tileset and tilemap from the masked image
rgbgfx "gfx/${NAME}.masked.png" --unique-tiles --tilemap "gfx/${NAME}.tilemap" --output "gfx/${NAME}.tileset.2bpp"

# Convert the 2bpp tileset to PNG (easier to work with)
rgbgfx "gfx/${NAME}.tileset.png" --reverse 1 --output "gfx/${NAME}.tileset.2bpp" && rm "gfx/${NAME}.tileset.2bpp"
