#!/usr/bin/env ruby
#
# Shift each row of a PNG image by 1px
#
# Usage:
#   tools/pngtranslate.rb <original_filename.png> <output_filename.png>

require_relative "lib/chunky_png"

# Shift the pixels of each row one more pixel on the right
filename = ARGV.first
image = ChunkyPNG::Image.from_file(filename)

(0...image.height).each do |x|
  image.rotate_row!(x, 1)
end
image.save(ARGV[1], color_mode: ChunkyPNG::COLOR_INDEXED)
