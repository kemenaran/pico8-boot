#!/usr/bin/env ruby
#
# Mask each 2nd and 3rd row in a PNG file
#
# Usage:
#   tools/pngscanlines.rb <original_filename.png> <output_filename.png>

require_relative "lib/chunky_png"
require_relative "lib/enumerator/with_coordinates"

filename = ARGV.first
image = ChunkyPNG::Image.from_file(filename)

# Mask each 1st and 2nd column
image.pixels.map!.with_coordinates(image.width) do |pixel, x, y|
  (x % 3 == 0) || (x % 3 == 1) ? ChunkyPNG::Color::BLACK : pixel
end

# Mask each 2nd and 3rd row
image.pixels.map!.with_coordinates(image.width) do |pixel, x, y|
  (y % 3 == 1) || (y % 3 == 2) ? ChunkyPNG::Color::BLACK : pixel
end
image.save(ARGV[1], color_mode: ChunkyPNG::COLOR_INDEXED)
