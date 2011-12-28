# Author:: Natsuki Kawai (natsuki.kawai@gmail.com)
# Copyright:: Copyright 2011 Natsuki Kawai
# License:: 2-clause BSDL or Ruby's


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

