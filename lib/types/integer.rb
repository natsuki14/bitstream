# Author:: Natsuki Kawai (natsuki.kawai@gmail.com)
# Copyright:: Copyright 2011, 2012 Natsuki Kawai
# License:: 2-clause BSDL or Ruby's

require 'bitstream/field-info'

module BitStream

  class Unsigned

    @be_instances = Hash.new do |hash, key|
      hash[key] = new(key, true)
    end

    @le_instances = Hash.new do |hash, key|
      hash[key] = new(key, false)
    end

    BE_SYMBOLS = [:big_endian, :be, :msb_first, :motorola, nil]
    LE_SYMBOLS = [:little_endian, :le, :lsb_first, :intel]

    def self.instance(props, bit_width)
      byte_order = props[:byte_order]
      if BE_SYMBOLS.include?(byte_order)
        @be_instances[bit_width]
      elsif LE_SYMBOLS.include?(byte_order)
        @le_instances[bit_width]
      else
        STDERR.puts("Unknown byte order #{byte_order.inspect}.",
                    "Assuming that the byte order is big endian.")
        @be_instances[bit_width]
      end
    end

    attr_reader :bit_width

    def initialize(bit_width, big_endian)
      @bit_width = bit_width
      @big_endian = big_endian
    end

    def length
      @bit_width
    end

    def read(s, offset)
      value = 0
      byteoffset = offset / 8
      bitoffset  = offset % 8
      bytelength = (@bit_width + bitoffset + 7) / 8

      bytes = s[byteoffset, bytelength].unpack('C*')
      bytes.reverse! unless @big_endian

      bytes.each do |b|
        value <<= 8
        value |= b
      end

      value &= ~(-1 << (bytelength * 8 - bitoffset))
      value >>= (8 - (@bit_width + bitoffset) % 8) % 8

      return FieldInfo.new(value, @bit_width)
    end

    def write(s, offset, value)
      byteoffset = offset / 8
      bitoffset  = offset % 8

      if bitoffset != 0
        raise "#{self.class.name}#write has not supported non-byte-aligned fields yet."
      end
      unless @big_endian
        raise "#{self.class.name}#write has not supported little endian yet."
      end

      i = 0
      tail = ""
      while value != 0
        index = byteoffset + @bit_width / 8 + i - 1
        if s.bytesize <= index
          tail.insert(0, [value & 0xff].pack('C'))
        else
          s[index] = [value & 0xff].pack('C')
        end
        value >>= 8
        i -= 1
      end
      s << tail

      return @bit_width
    end

  end

  class Signed

    @instances = Hash.new do |hash, key|
      hash[key] = new(key)
    end

    def self.instance(props, bit_width)
      unsigned = Unsigned.instance(props, bit_width)
      return @instances[unsigned]
    end

    def initialize(unsigned)
      @unsigned = unsigned
    end

    def length
      @unsigned.length
    end

    def read(s, offset)
      info = @unsigned.read(s, offset)
      val = info[:value]
      len = info[:length]
      mask = -1 << (len - 1)
      if (val & mask) != 0
        val |= mask
      end
      return FieldInfo.new(val, len)
    end

    def write(s, offset, value)
      mask = ~(-1 << len)
      value &= mask
      return @unsigned.write(s, offset, value)
    end

  end

end
