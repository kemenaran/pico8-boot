class ChunkyPNG::Image
  def self.from_pixels(width, height, pixels)
    from_rgba_stream(width, height, pixels.pack("NX" * pixels.length))
  end

  # Return an enumerator that yields each row as an array of pixels.
  # @return [Enumerator]
  def rows
    pixels.each_slice(width)
  end

  # Rotate the pixels of a single row by `count` pixels.
  # @param [Integer] x row index
  # @param [Integer] count shit amount
  def rotate_row!(x, count)
    replace_row!(x, row(x).rotate(count))
  end

  TILE_WIDTH = 8
  TILE_HEIGHT = 8
  TILE_SIZE = 64

  def tiles_count
    width * height / TILE_SIZE
  end

  # Return the n-th 8x8 pixels tile in the picture
  # (Read from left-to-right, top-to-bottom)
  # @return [Array] an array of colors (one color per pixel)
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
  #
  # FIXME: this conflicts with an already existing "column" method; rename to tile_column(c)
  def column(c)
    total_columns = width / TILE_WIDTH
    tiles_per_row = tiles.length / total_columns
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
