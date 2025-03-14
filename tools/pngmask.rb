#!/usr/bin/env ruby
#
# Mask an image with a triangular fill color on the lower-left side and upper-right side.
# The black color increases by 4px every 4 rows.
#
# |------------|          |------------|
# |            |          |#       ####|
# |            |    =>    |##       ###|
# |            |          |###       ##|
# |            |          |####       #|
# |------------|          |------------|
#
#
# The fill color is assumed to be the darkest of the palette (at index 3).
# However, when using the `--palette-fixed-colors-alternated` option, the fill color will be alternatively the darkest (at index 3) and second-lightest color (at index 1).
#
# Usage:
#   tools/pngmask.rb [--repeat N] [--palette-fixed-colors-alternated] <input_filename.png> <output_filename.png>

require "debug"
require "optparse"
require_relative "lib/chunky_png"

options = { repeat: 1, palette_fixed_colors_alternated: false }
OptionParser.new do |opts|
  opts.banner = "Usage: tools/pngmask.rb <original_filename.png> <output_filename.png>"
  opts.on("-r N", "--repeat N", "Repeat the source image N times horizontaly before masking") { |n| options[:repeat] = n.to_i }
  opts.on("-a", "--palette-fixed-colors-alternated", "Consider that a palette's black color is at index 3 (instead of 1) every other column") { |o| options[:palette_fixed_colors_alternated] = true }
end.parse!
raise "Invalid arguments count" if ARGV.count != 2
input_filename = ARGV[0]
output_filename = ARGV[1]

# 1. Open the input image
input_image = ChunkyPNG::Image.from_file(input_filename)

# 2. Repeat the image if needed
repeat = options[:repeat]
output_width = input_image.width * repeat
output_height = input_image.height
image = ChunkyPNG::Image.new(output_width, output_height)
repeat.times do |i|
  image.replace!(input_image, input_image.width * i, 0)
end

# 3. Compute the mask pattern
TILE_WIDTH = 8
palette_2bpp = input_image.palette.to_a.sort.reverse
black_color = if options[:palette_fixed_colors_alternated]
  [
    palette_2bpp[1], # even columns
    palette_2bpp[3], # odd columns
  ]
else
  [
    palette_2bpp[3], # even columns
    palette_2bpp[3], # odd columns
  ]
end
mask_pattern = Array.new(output_width) do |i|
  column_index = i / TILE_WIDTH
  black_color[column_index % 2]
end

# 4. Mask the image
image.rows.with_index.map do |row, y|
  left_mask_length = (y / 4) * 4 + 1
  unmasked_length = image.height
  right_mask_start = left_mask_length + unmasked_length
  right_mask_length = row.length - (left_mask_length + unmasked_length)
  masked_row = mask_pattern.slice(0, left_mask_length) + row.slice(left_mask_length, unmasked_length) + mask_pattern.slice(right_mask_start, right_mask_length)
  image.replace_row!(y, masked_row)
end

# 5. Save the output image
image.save(output_filename)
