module BitStream

  class Char
  
    def self.fixed_length?
      true
    end

    def self.read(s, offset)
      byteoffset = offset / 8
      bitoffset  = offset % 8

      value = s[byteoffset]

      return [value, 8]
    end

    def self.write(s, offset, value)
    end
  end
end

