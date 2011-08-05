require 'types/string-utils'

module BitStream

  class String

    def initialize(byte_len)
      @byte_len = byte_len
    end

    def fixed_length?
      true
    end

    def read(s, offset)
      bitoffset = offset % 8
      head = offset / 8
      tail = (offset + @byte_len * 8 + 7) / 8
      val = s[head...tail]
      Utils.bit_lshift(val, bitoffset)
      val.slice!(val.size - 1) if bitoffset != 0

      [val, @byte_len * 8]
    end

    def write(s, offset, data)
      head = offset / 8
      tail = (offset + @byte_len * 8 + 7) / 8
      s[head...tail] = data
      return s
    end

  end

end
