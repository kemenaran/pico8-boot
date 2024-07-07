#!/usr/bin/env ruby
#
# Shift each row of a PNG image by 1px every line
#
# Usage:
#   tools/pngshift.rb <original_filename.png> <output_filename.png>

require 'bundler/inline'

# Download, install and require dependencies
gemfile do
  source 'https://rubygems.org'
  gem 'chunky_png'
end

# Add extension methods to the image class
class ChunkyPNG::Image
  def shift_row!(x, count)
    replace_row!(x, row(x).rotate(count))
  end
end

# Shift the pixels of each row one more pixel on the right
filename = ARGV.first
image = ChunkyPNG::Image.from_file(filename)
(0...image.height).each do |x|
  additionnal_offset = [
    0,
    1,
    2,
    1,
    0,
    1,
    2,
    1
  ][x % 8]
  image.shift_row!(x, -(x - additionnal_offset) - 1)
end
image.save(ARGV[1], color_mode: ChunkyPNG::COLOR_INDEXED)
