module BitStream

  class UnsignedInt

    @instances = Hash.new do |hash, key|
      hash[key] = new key
    end

    def self.instance(bit_width)
      @instances[bit_width]
    end

    attr_reader :bit_width

    def initialize(bit_width)
      @bit_width = bit_width
    end

    def fixed_length?
      true
    end

    def read(s, offset)
      puts "#{s.inspect} #{offset}"
      value = 0
      byteoffset = offset / 8
      bitoffset  = offset % 8
      bytelength = (@bit_width + bitoffset + 7) / 8

      bytelength.times do |i|
        value <<= 8
        value |= s[i + byteoffset].unpack('C')[0]
      end
      value &= ~(-1 << (bytelength * 8 - bitoffset))
      value >>= (8 - (@bit_width + bitoffset) % 8) % 8

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
