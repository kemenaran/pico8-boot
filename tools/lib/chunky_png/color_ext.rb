module ChunkyPNG::Color
  def self.to_bgr555(c)
    r5, g5, b5 = to_truecolor_bytes(c).map { |component| (component * 31 / 255.0).round }
    (b5 << (10) | (g5 << 5) | r5)
  end

  def self.to_asm(c)
    "$%04X" % to_bgr555(c)
  end
end
