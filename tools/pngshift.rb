#!/usr/bin/env ruby
#
# Shift each row of a PNG image by a sequence of wavy pixels every line
#
# Usage:
#   tools/pngshift.rb <original_filename.png> <output_filename.png>

require_relative "lib/chunky_png"

filename = ARGV.first
image = ChunkyPNG::Image.from_file(filename)

OFFSET_SEQUENCE = [0, 1, 2, 1]

# Shift the pixels of each row one more pixel (plus offset) on the right
(0...image.height).each do |x|
  additionnal_offset = OFFSET_SEQUENCE[x % 4]
  image.rotate_row!(x, -x + additionnal_offset - 1)
end
image.save(ARGV[1], color_mode: ChunkyPNG::COLOR_INDEXED)
