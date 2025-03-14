# A collection of 4 colors
class Palette
  include Enumerable

  def initialize(initial_colors = [nil, nil, nil, nil])
    self.colors = initial_colors
  end

  def colors
    @colors
  end

  def colors=(new_colors)
    raise "Palette must be initialized with exactly 4 values" if new_colors.length != 4
    @colors = Array.new(new_colors)
  end

  def each(...)
    @colors.each(...)
  end

  def <<(new_color)
    return self if @colors.include?(new_color)
    first_free_slot = @colors.index(nil)
    raise "Attempted to add #{ChunkyPNG::Color.to_hex(new_color, false)} to a full palette (#{self.inspect})" if first_free_slot.nil?
    @colors[first_free_slot] = new_color
    self
  end

  def inspect
    hex_colors = @colors.map { |c| c.nil? ? "nil" : ChunkyPNG::Color.to_hex(c, false) }
    "#<#{self.class.name} [#{hex_colors.join(", ")}]>"
  end

  def freeze
    @colors.freeze
    super
  end

  def dup(default_color: nil)
    new_palette = super()
    new_colors = colors.map { |c| c.nil? ? default_color : c }
    new_palette.instance_variable_set(:@colors, new_colors)
    new_palette
  end

  # Operations

  class MissingColorError < StandardError
  end

  def transpose(color, into:)
    other_palette = into
    index_in_palette = @colors.index(color)
    raise MissingColorError, "Color \"#{ChunkyPNG::Color.to_hex(color, false)}\" not found in #{inspect}" if index_in_palette.nil?
    other_palette.colors[index_in_palette]
  end

  # Fixed and variable parts support

  def fixed_colors_start
    @fixed_colors_start = 0 if @fixed_colors_start.nil?
    @fixed_colors_start
  end

  def fixed_colors_start=(start)
    raise ArgumentError.new("start must be between 0 and 3") if !start.between?(0, 3)
    @fixed_colors_start = start
  end

  def fixed_colors
    @colors.rotate(fixed_colors_start).first(2)
  end

  def fixed_colors=(colors_pair)
    raise ArgumentError.new("argument must be an array of two elements") if colors_pair.length != 2
    @colors[fixed_colors_start]           = colors_pair[0]
    @colors[(fixed_colors_start + 1) % 4] = colors_pair[1]
  end

  def variable_colors
    @colors.rotate(fixed_colors_start).last(2)
  end

  def variable_colors=(colors_pair)
    raise ArgumentError.new("argument must be an array of two elements") if colors_pair.length != 2
    @colors[(fixed_colors_start + 2) % 4] = colors_pair[0]
    @colors[(fixed_colors_start + 3) % 4] = colors_pair[1]
  end
end
