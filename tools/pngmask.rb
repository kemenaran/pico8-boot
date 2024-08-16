#!/usr/bin/env ruby
#
# Mask an image with a triangular fill color on the lower-left side and upper-right side.
# The fill color increases by 4px every 4 rows.
#
# |------------|          |------------|
# |            |          |#       ####|
# |            |    =>    |##       ###|
# |            |          |###       ##|
# |            |          |####       #|
# |------------|          |------------|
#
# Usage:
#   tools/pngmask.rb [--repeat N] [--fill-color #0099FF] <input_filename.png> <output_filename.png>

require "debug"
require "optparse"
require_relative "lib/chunky_png"

DEFAULT_MASK_COLOR = ChunkyPNG::Color::BLACK

options = { repeat: 1, mask_color: DEFAULT_MASK_COLOR }
OptionParser.new do |opts|
  opts.banner = "Usage: tools/pngmask.rb <original_filename.png> <output_filename.png>"
  opts.on("-r N", "--repeat N", "Repeat the source image N times horizontaly before masking") { |n| options[:repeat] = n.to_i }
  opts.on("-c COLOR", "--color COLOR", "Masking color") { |color| options[:mask_color] = ChunkyPNG::Color.parse(color) }
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

# 3. Mask the image
mask_color = options[:mask_color]
image.rows.with_index.map do |row, y|
  left_mask_length = (y / 4) * 4
  right_mask_length = image.height - 1 - y
  remaining_length = row.length - left_mask_length - right_mask_length
  masked_row = ([mask_color] * left_mask_length) + row.slice(left_mask_length, remaining_length) + ([mask_color] * right_mask_length)
  image.replace_row!(y, masked_row)
end

# 4. Save the output image
image.save(output_filename)
