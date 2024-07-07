#!/usr/bin/env ruby
#
# Display various statistics and info about colors in a PNG file
#
# Usage:
#   tools/pngstats.rb <filename.png>

require "debug"

begin
  require "chunky_png"
rescue
  # Download and install dependencies
  require "bundler/inline"
  gemfile do
    source "https://rubygems.org"
    gem "chunky_png"
  end
end

# Add extension methods to the image class
class ChunkyPNG::Image
  TILE_WIDTH = 8
  TILE_HEIGHT = 8
  TILE_SIZE = 64

  def tiles_count
    width * height / TILE_SIZE
  end

  # Return the n-th 8x8 pixels tile in the picture
  # (Read from left-to-right, top-to-bottom)
  # @return [Array]
  def tile(n)
    tile = Array.new()
    tiles_per_row = width / TILE_WIDTH
    row = (n / tiles_per_row)
    column = (n % tiles_per_row)
    (0...TILE_WIDTH).each do |i|
      row_start = (row * width + column) * TILE_WIDTH + (i * width)
      tile.concat(pixels[row_start...(row_start + TILE_WIDTH)])
    end
    tile
  end

  # Return an array of all pixels in the image, grouped into 8x8px tiles
  # @return [Array<Array>]
  def tiles
    @tiles ||= (0...tiles_count).map { |i| tile(i) }
  end

  # def row(r, total: n)
  #   tiles_per_row = tiles.length / n
  #   tiles.
  # end

  # Return all tiles for the given column
  # @return [Array<Array>]
  def column(c, total:)
    tiles_per_row = tiles.length / total
    tiles.each_slice(tiles_per_row).map { |row| row[c] }
  end

  # Return the n-th 8x1 pixels tile row in the picture
  # (Read from left-to-right, top-to-bottom)
  # @return [Array]
  def tile_row(n)
    tiles_per_row = width / TILE_WIDTH
    row = (n / tiles_per_row)
    column = (n % tiles_per_row)
    row_start = row * width + column * TILE_WIDTH
    pixels[row_start...(row_start + TILE_WIDTH)]
  end

  def tile_rows
    tile_rows_count = tiles_count * 8
    @tile_rows ||= (0...tile_rows_count).map { |i| tile_row(i) }
  end
end

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
COLUMNS_COUNT = 16
8.times do |i|
  colors_tally = image
    .column(i, total: COLUMNS_COUNT)
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

