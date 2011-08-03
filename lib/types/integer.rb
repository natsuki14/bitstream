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

      i = 0
      tail = ""
      while value != 0
        index = byteoffset + @bit_width / 8 + i - 1
        if s.bytesize <= index
          tail.insert(0, [value & 0xff].pack('C'))
        else
          s[index] = [value & 0xff].pack('C')
        end
        value >>= 8
        i -= 1
      end
      s << tail
    end

  end

end
