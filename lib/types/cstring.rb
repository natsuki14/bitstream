module BitStream

  class Cstring

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

      val.slice!(val.size - 1)
      return [val, 8 * val.size]
    end

    def write(s, offset, data)
    end

  end

end
