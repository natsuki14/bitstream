module BitStream

  class UnsignedInt

    attr_reader :bit_width

    def initialize(bit_width)
      @bit_width = bit_width
    end

    def fixed_length?
      true
    end

    def read(s, offset)
      # TODO: Support non-byte-aligned fields.

      value = 0
      byteoffset = offset / 8
      bitoffset  = offset % 8

      if bitoffset != 0
        throw "#{self.class.name} has not supported non-byte-aligned fields yet."
      end

      (@bit_width / 8).times do |i|
        value <<= 8
        p s, byteoffset
        value |= s[i + byteoffset].unpack('C')[0]
      end
      return [value, @bit_width]
    end

    def write(s, offset, value)
      byteoffset = offset / 8
      bitoffset  = offset % 8

      if bitoffset != 0
        throw "#{self.class.name} has not supported non-byte-aligned fields yet."
      end

      index = 0
      while value != 0
        s[byteoffset + @bit_width / 8 + index] = [value & 0xff].pack('C')
        value >>= 8
        index -= 1
      end
    end

  end

end
