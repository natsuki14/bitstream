module BitStream

  module Utils

    def self.bit_lshift(s, bit)
      if bit != 0
        last_byte = nil
        (s.size - 1).times do |i|
          dbyte = s[i..(i + 1)].unpack('n')[0]
          c = dbyte >> (8 - bit)
          s[i] = (c & 0xff).chr
        end
      end
    end
    
    def self.bit_rshift(s, bit)
      if bit != 0
        s << "\0"
        first_byte = nil
        (s.size - 1).downto 1 do |i|
          dbyte = s[(i - 1)..i].unpack('n')[0]
          c = dbyte >> bit
          s[i] = (c & 0xff).chr
          first_byte = c >> 8
        end
        s[0] = first_byte.chr
      end
    end

  end

end
