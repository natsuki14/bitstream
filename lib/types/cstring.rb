module BitStream

  class Cstring

    @instance = new

    def self.instance
      @instance
    end

    def fixed_length?
      false
    end

    def read(s, offset)
      byteindex = offset / 8
      bitindex  = offset % 8
      val = ""
      begin
        byte = s[byteindex].unpack('C')[0]
        val << byte
        byteindex += 1
      end while byte != 0

      bytelen = val.size
      val.slice!(val.size - 1)
      return [val, 8 * bytelen]
    end

    def write(s, offset, data)
    end

  end

end
