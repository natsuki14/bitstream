# Author:: Natsuki Kawai (natsuki.kawai@gmail.com)
# Copyright:: Copyright 2011, 2012 Natsuki Kawai
# License:: 2-clause BSDL or Ruby's

require 'bitstream/field-info'

module BitStream

  class Cstring

    @instance = new

    def self.instance(props)
      @instance
    end

    def length
      nil
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
      return FieldInfo.new(val, 8 * bytelen)
    end

    def write(s, offset, data)
    end

  end

end
