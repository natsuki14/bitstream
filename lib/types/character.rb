# Author:: Natsuki Kawai (natsuki.kawai@gmail.com)
# Copyright:: Copyright 2011, 2012 Natsuki Kawai
# License:: 2-clause BSDL or Ruby's

require 'bitstream/field-info'

module BitStream

  class Char
    
    LENGTH = 8

    @instance = new

    def self.instance(props)
      @instance
    end

    def length
      LENGTH
    end

    def read(s, offset)
      byteoffset = offset / 8
      bitoffset  = offset % 8

      value = s[byteoffset]

      return FieldInfo.new(value, LENGTH)
    end

    def write(s, offset, value)
    end

  end

end

