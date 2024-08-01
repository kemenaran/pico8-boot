#!/usr/bin/env ruby
#
# Display various statistics and info about colors in a PNG file
#
# Usage:
#   tools/pngstats.rb <filename.png>

require "debug"
require_relative "lib/chunky-png-image-ext"

def puts_square(enumerable)
  enumerable.each_slice(16) { |slice| puts slice.join(' ') }
end

filename = ARGV.first
image = ChunkyPNG::Image.from_file(filename)

puts "Total number of colors: #{image.palette.length}"
puts "Number of tiles: #{image.tiles.length}"
puts "Max number of colors per tile:"
color_count_per_tile = image
  .tiles
  .map { |tile| Set.new(tile) }
  .map(&:length)
#puts_square(color_count_per_tile)
puts color_count_per_tile.max

puts "Max number of colors per 8x1 pixel blocks:"
color_count_per_tile_row = image
  .tile_rows
  .map { |tile_row| Set.new(tile_row) }
  .map(&:length)
#puts_square(color_count_per_tile_row)
puts color_count_per_tile_row.max

# puts "Palettes per scanline:"
# palette_count_per_scanline = image
#   .tile_rows
#   .each_slice(16).map do |tile_rows_line|
#     Set.new(tile_rows_line.map { |tile_row| Set.new(tile_row) })
#   end.map(&:length)
# palette_count_per_scanline.each { |c| puts c }

puts "Most frequent colors by column:"
8.times do |i|
  colors_tally = image
    .column(i)
    .flatten
    .tally
    .sort_by { |_, value| value }
    .reverse
    .to_h
  puts "Colors for column #{i}:"
  pp colors_tally
end

# TODO:
# For each column:
# - Build a partial palette with the first 3 mot frequent colors
# - For each 8x1 slice:
#   - count the number of colors not in the partial palette, and print a warning if > 1

