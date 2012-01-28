# Author:: Natsuki Kawai (natsuki.kawai@gmail.com)
# Copyright:: Copyright (c) 2012 Natsuki Kawai
# License:: 2-clause BSDL or Ruby's

class LazyString

  SubString = Struct.new(:start, :value)

  class LazySubString

    def initialize(value, start, size)
      @start = start
      @size = size
      @value = value
    end

    def [](*args)
      if args.size == 2
        start = args[0]
        length = args[1]
        return @value[@start + start, length]
      else
        raise NotImplementedError
      end
    end

    def to_str
      @value[@start, @size]
    end
    alias :to_s :to_str

    attr_reader :size
    alias :length :size

  end

  def initialize(*args)
    @size = 0
    @chain = []

    if args.size == 3
      @chain << SubString.new(0, LazySubString.new(*args))
      @size = args[2]
    end
  end

  def <<(other)
    if other.respond_to?(:to_int)
      return self << ('' << other)
    end
    
    @chain << SubString.new(@size, other)
    @size += other.size
  end

  def [](*args)
    if args.size == 2
      start = args[0]
      last  = start + args[1]
      length = args[1]
      e = @chain.each
      
      curr = nil
      begin
        curr = e.next
      end while curr.start + curr.value.size < start
      
      value = curr.value
      sub_start = start - curr.start
      sub_length = value.size - sub_start
      if sub_length >= length
        return LazyString.new(value, sub_start, length)
      else
        res = LazyString.new(value, sub_start, sub_length)
        length -= sub_length
        while length > 0
          curr = e.next
          if length < curr.value.length
            res << LazyString.new(curr.value, 0, length)
            length = 0
          else
            res << curr.value
            length -= curr.value.length
          end
        end
        return res
      end
    elsif args.respond_to?(:to_int)
      raise NotImplementedError
    else # args is one Range object.
      raise NotImplementedError
    end
  end
  
  def to_str
    res = ''
    @chain.each do |substr|
      res << substr.value
    end
    return res
  end
  alias :to_s :to_str
  
  attr_reader :size
  alias :length :size

end
