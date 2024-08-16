#!/usr/bin/env ruby
#
# Shift the rows of a PNG image by 4 pixels every 4 rows
#
# Usage:
#   tools/pngshift.rb <original_filename.png> <output_filename.png>

require_relative "lib/chunky_png"

filename = ARGV.first
image = ChunkyPNG::Image.from_file(filename)

# Shift the rows by 4 pixels every 4 rows
(0...image.height).each do |x|
  count = (x / 4) * 4 + 1
  image.rotate_row!(x, - count)
end
image.save(ARGV[1], color_mode: ChunkyPNG::COLOR_INDEXED)

# Result:
# -1
# -1
# -1
# -1
# -5
# -5
# -5
# -5
# -9
# -9
# -9
# -9
# -13
# -13
# -13
# -13
