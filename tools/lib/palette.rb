# A collection of 4 colors
class Palette
  include Enumerable

  def initialize(initial_colors = [nil, nil, nil, nil])
    self.colors = initial_colors
  end

  def colors
    @colors
  end

  def colors_with_default(default_color)
    @colors.map { |c| c.nil? ? default_color : c }
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
    raise "Palette is already full" if first_free_slot.nil?
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

  def dup
    super.tap { |new_palette| new_palette.instance_variable_set(:@colors, colors.dup) }
  end

  # Fixed and variable parts support

  def variable_colors
    @colors.first(2)
  end

  def variable_colors=(colors_pair)
    raise ArgumentError.new("argument must be an array of two elements") if colors_pair.length != 2
    @colors[0] = colors_pair[0]
    @colors[1] = colors_pair[1]
  end

  def fixed_colors
    @colors.last(2)
  end

  def fixed_colors=(colors_pair)
    raise ArgumentError.new("argument must be an array of two elements") if colors_pair.length != 2
    @colors[2] = colors_pair[0]
    @colors[3] = colors_pair[1]
  end
end
