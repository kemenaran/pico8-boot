#!/usr/bin/env ruby
#
# Encode a PNG file into the format expected by pico8-boot; that is:
# - A 4-colors grayscale PNG picture,
# - A list of color pairs to be updated on each scanline.
#
# Usage:
#   tools/encode.rb <filename.png>

require "debug"
require "logger"
require "optparse"
require_relative "lib/chunky_png"
require_relative "lib/palette"

logger = Logger.new(STDERR)
logger.level = Logger::UNKNOWN

OptionParser.new do |opts|
  opts.banner = "Usage: tools/encode.rb [--verbose] input_image.png"
  opts.on('-v', '--verbose') { |o| logger.level = Logger::DEBUG }
end.parse!

# 1. Open the source image
filename = ARGV.first
image = ChunkyPNG::Image.from_file(filename)

# 2. Crop it to the first 8 columns
# (the source image is assumed to be repeating after than)
columns_count = 8
image.crop!(0, 0, columns_count * ChunkyPNG::Image::TILE_WIDTH, image.height)

# 3. Build the fixed part of the palettes.
#
# Each palette of 4 colors is split in two parts:
# - 2 colors can be changed on every scanline,
# - 2 colors are shared between all scanlines (fixed).
#
# Build the fixed part of each palette, by computing the most frequent colors of each column.
initial_palettes_set = []
# For each column (we only take the first 8, as the picture will be mirrored)
columns_count.times do |i|
  # Compute the two most frequent colors in this column
  most_frequent_colors = image
    .column(i)
    .flatten
    .tally
    .sort_by { |_, value| -value } # most frequent colors first
    .map { |tally| tally.first(2) }
    .to_h
    .keys    # extract colors from tally
    .take(2) # 2 most frequent colors
    .reverse # actual color first, black last
  initial_palettes_set[i] = Palette.new
    .tap { |palette| palette.fixed_colors = [most_frequent_colors[0], most_frequent_colors[1]] }
    .freeze
  logger.debug "Initial palette for column #{i}: #{initial_palettes_set[i].inspect}"
end
initial_palettes_set.freeze

# 4. Complete the palettes set for each scanline with the variable colors
palettes_sets_for_line = []
lines = image.height
lines.times do |i|
  # Initialize this line's palettes set with the fixed colors
  line_palettes_set = initial_palettes_set.map(&:dup)
  # For each 8 pixels span of the line…
  image.row(i).each_slice(8).with_index do |tile_row_pixels, column|
    # Add the required colors to render this span to the palette.
    # (This will raise if the span require more than 4 colors)
    palette_for_column = line_palettes_set[column]
    tile_row_pixels.each { |pixel_color| palette_for_column << pixel_color }
  end
  palettes_sets_for_line[i] = line_palettes_set
end

#test_line_index = 3
#puts "Palettes set for line #{test_line_index}:\n#{palettes_sets_for_line[test_line_index].map(&:inspect).join("\n")}"

#indexed_image = IndexedImage.new(width: image.width, height: image.height)

# 5. Output the palettes to an assembly text file
MAGENTA = ChunkyPNG::Color.from_hex("#CB006A")
# Write the palettes set for line 0
$stdout.puts("InitialPalettesSet:")
initial_palettes_set.map(&:dup).each do |initial_palette|
  $stdout.puts("  dw #{initial_palette.colors_with_default(MAGENTA).map { |c| ChunkyPNG::Color.to_asm(c) }.join(", ") }")
end

# Write colors pairs to update on each scanline
$stdout.puts("")
$stdout.puts("PalettesDiffForScanline:")
palettes_sets_for_line.each.with_index do |palettes_set_for_scanline, line|
  $stdout.puts "._#{line}"
  palettes_set_for_scanline.each do |palette|
    $stdout.puts("  dw #{palette.colors_with_default(MAGENTA).take(2).map { |c| ChunkyPNG::Color.to_asm(c) }.join(", ") }")
  end
end
