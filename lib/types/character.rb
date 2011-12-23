module BitStream

  class Char

    @instance = new

    def self.instance(props)
      @instance
    end

    def length
      8
    end

    def read(s, offset)
      byteoffset = offset / 8
      bitoffset  = offset % 8

      value = s[byteoffset]

      return [value, 8]
    end

    def write(s, offset, value)
    end

  end

end

