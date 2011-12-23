require 'types/string-utils'

# Used to debug.
#class String
#  def to_bin
#    ret = ''
#    each_byte do |byte|
#      ret << byte.to_s(2)
#    end
#    ret = '0' * (8 - ret.size % 8) + ret if ret.size % 8 != 0
#    ret
#  end
#end

module BitStream

  class String

    def self.instance(props, byte_len)
      new byte_len
    end

    def initialize(byte_len)
      @byte_len = byte_len
    end

    def length
      @byte_len * 8
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
      if offset % 8 != 0
        bitoffset = offset % 8
        Utils.bit_rshift(data, bitoffset)
        s[head] = ((data[0].ord & 0xff >> bitoffset) | (s[head].ord & 0xff << (8 - bitoffset))).chr
        s[tail - 1] = (data[data.size - 1].ord & 0xff << (8 - bitoffset)).chr
        s[(head + 1)..(tail - 2)] = data[1..(data.size - 2)]
      else
        s[head...tail] = data
      end
      return @byte_len * 8
    end

  end

end
