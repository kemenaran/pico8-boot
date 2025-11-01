#!/usr/bin/env ruby
#
# Encode a PNG file into the format expected by pico8-boot; that is:
# - A 4-colors grayscale PNG picture,
# - A list of color pairs to be updated on each scanline.
#
# Usage:
#   tools/encode.rb --output-palettes palettes.asm --output-png 2bpp.png <source_image.png>

require "debug"
require "logger"
require "optparse"
require_relative "lib/chunky_png"
require_relative "lib/palette"
require_relative "lib/enumerator/with_coordinates"

logger = Logger.new(STDERR)
logger.level = Logger::UNKNOWN

options = { palette_fixed_colors_alternated: false }
OptionParser.new do |opts|
  opts.banner = "Usage: tools/encode.rb [--verbose] input_image.png"
  opts.on("-v", "--verbose") { |o| logger.level = Logger::DEBUG }
  opts.on("-a", "--palette-fixed-colors-alternated", "Put the palette's fixed colors last (instead of first) every other column.") { |o| options[:palette_fixed_colors_alternated] = true }
  opts.on("-p FILENAME", "--output-palettes FILENAME") { |filename| options[:output_palettes] = filename }
  opts.on("-b FILENAME", "--output-png FILENAME") { |filename| options[:output_png] = filename }
end.parse!

logger.debug({options:, ARGV:})

# 1. Open the source image
filename = ARGV.first
image_name = File.basename(filename, '.png')
image = ChunkyPNG::Image.from_file(filename)

# 2. Build the fixed part of the palettes.
#
# Each palette of 4 colors is split in two parts:
# - 2 colors can be changed on every scanline,
# - 2 colors are shared between all scanlines (fixed).
#
# Build the fixed part of each palette, by computing the most frequent colors of each column.
initial_palettes_set = []
# For each column (we only take the first 8, as the main colors repeats afterwards)
COLUMNS_COUNT = 8
COLUMNS_COUNT.times do |i|
  # Compute the two most frequent colors in this column
  most_frequent_colors = image
    .column(i)
    .flatten
    .tally
    .sort_by { |_, value| -value } # most frequent colors first
    .map { |tally| tally.first(2) }
    .to_h
    .keys    # extract colors from tally
    .then { |sorted_colors| [sorted_colors[0], sorted_colors[1]] } # 2 most frequent colors (even if one of them is nil)
    .reverse # actual color first, black last
  initial_palettes_set[i] = Palette.new
    .tap { |palette| palette.fixed_colors_start = options[:palette_fixed_colors_alternated] ? (i % 2) * 2 : 0 } # Alternate between having the fixed colors pair at the beginning or at the end
    .tap { |palette| palette.fixed_colors = [most_frequent_colors[0], most_frequent_colors[1]] }
    .freeze
  logger.debug "Initial palette for column #{i}: #{initial_palettes_set[i].inspect}"
end
initial_palettes_set.freeze

# 3. Complete the palettes of each scanline with the variable colors
palettes_sets_for_line = image.rows.map.with_index do |row, row_index|
  # Initialize this line's palettes set with the fixed colors
  line_palettes_set = initial_palettes_set.map(&:dup)
  # For each sliver of the line…
  row.each_slice(8).with_index do |sliver, column|
    # Add the required colors to render this span to the palette.
    # (This will raise if the span require more than 4 colors)
    column_palette = line_palettes_set[column % COLUMNS_COUNT]
    sliver.each { |pixel_color| column_palette << pixel_color rescue nil }
  end
  line_palettes_set
end

# 5. Output the grayscale 2bpp resulting image
if options[:output_png]
  GRAYSCALE_PALETTE = Palette.new([255, 172, 86, 0].map(&ChunkyPNG::Color.method(:grayscale)))
  image_2bpp = ChunkyPNG::Image.new(image.width, image.height)
  Random.new(0) # for deterministic Array#sample

  image.pixels.each.with_coordinates(image.width) do |pixel, x, y|
    column = x / ChunkyPNG::Image::TILE_WIDTH
    column_palette = palettes_sets_for_line[y][column % COLUMNS_COUNT]
    indexed_pixel = begin
      column_palette.transpose(pixel, into: GRAYSCALE_PALETTE)
    rescue Palette::MissingColorError
      fallback_color = column_palette.variable_colors[column % 2] # pick the first or second variable color, but the same for all pixels of a column
      column_palette.transpose(fallback_color, into: GRAYSCALE_PALETTE)
    end
    image_2bpp.set_pixel(x, y, indexed_pixel)
  end
  # By default, ChunkyPNG::Image will compute the palette from the canvas pixels, excluding unused colors.
  # Here we want all 4 grayscale colors to be present in the PNG palette (for compatibility with other tools in this project).
  def image_2bpp.palette
    ChunkyPNG::Palette.new(GRAYSCALE_PALETTE.colors)
  end
  image_2bpp.save(options[:output_png], { color_mode: ChunkyPNG::COLOR_INDEXED })
end

# 6. Output the palettes for each line to an assembly text file
if options[:output_palettes]
  MAGENTA = ChunkyPNG::Color.from_hex("#FF40FF")
  File.open(options[:output_palettes], "w") do |f|
    # Write the section header
    f.puts("SECTION \"#{File.basename(f.path)}\", ROMX")
    f.puts("")
    # Write the palettes set for line 0
    f.puts("Frame#{image_name}InitialPalettes:")
    palettes_sets_for_line[0].each do |initial_palette|
      f.puts("  dw #{initial_palette.dup(default_color: MAGENTA).map { |c| ChunkyPNG::Color.to_asm(c) }.join(", ") }")
    end
    # Write colors pairs to update on each scanline
    f.puts("")
    f.puts("; Palettes diff for each scanline")
    f.puts("Frame#{image_name}PalettesDiffs:")
    palettes_sets_for_line.each.with_index do |palettes_set_for_scanline, line|
      f.puts "._#{line}"
      palettes_set_for_scanline.each do |palette|
        f.puts("  dw #{palette.dup(default_color: MAGENTA).variable_colors.map { |c| ChunkyPNG::Color.to_asm(c) }.join(", ") }")
      end
    end
  end
end
