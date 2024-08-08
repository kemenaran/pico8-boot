class Enumerator
  # Given consecutive elements arranged in a 2d plane, iterates the given block for each element
  # with x and y coordinates.
  # If no block is given, returns a new Enumerator that includes the coordinates.
  def with_coordinates(width, &block)
    if block_given?
      each.with_index do |value, i|
        x = i % width
        y = i / width
        yield value, x, y
      end
    else
      Enumerator.new do |y|
        with_coordinates(width, &y)
      end
    end
  end
end
