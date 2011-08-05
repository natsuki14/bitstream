module BitStream

  module Utils

    def self.bit_lshift(s, bit)
      if bit != 0
        (s.size - 1).times do |i|
          c = s[i..(i + 1)].unpack('n')[0] >> (8 - bit)
          s[i] = [c].pack('C')
        end
      end
    end

  end

end
