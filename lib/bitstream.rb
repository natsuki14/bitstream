# Author:: Natsuki Kawai (natsuki.kawai@gmail.com)
# Copyright:: Copyright (c) 2011, 2012 Natsuki Kawai
# License:: 2-clause BSDL or Ruby's

require 'random-accessible'
require 'lazy-string'

require 'types/integer'
require 'types/string'
require 'types/cstring'
require 'types/character'

require 'bitstream/utils'

module BitStream

  class BitStreamError < Exception
  end

  Properties = Struct.new(
    :curr_offset,
    :fields,
    :mode,
    :raw_data,
    :initial_offset,
    :user_props,
    :eval_queue,
    :substreams
  )

  class ArrayProxy

    include RandomAccessible

    def initialize(instance)
      @fields = []
      @values = []
      @updated = []
      @instance = instance
      @size = 0
    end

    def add_field(field)
      @fields << field
      @size += 1
    end

    def get_field(pos)
      @fields[pos]
    end

    def read_access(pos)
      unless @updated[pos]
        field = @fields[pos]
        @values[pos] = field.value
        @fields[pos] = nil
        @updated[pos] = true
      end
      return @values[pos]
    end

    def write_access(pos, val)
      @fields[pos] = nil
      @values[pos] = val
      @updated[pos] = true
    end

    def shrink(n)
      @fields.pop(n)
      @size -= n
      dif = @values.size - @size
      if dif > 0
        @values.pop(dif)
        @updated.pop(dif)
      end
    end

    attr_reader :size

  end

  # TODO: Use data structure that enqueues and dequeues in O(1).
  class Queue < Array

    alias :enq :push
    alias :deq :shift
    alias :peek_front :first
    alias :peek_back :last

  end

  class NestWrapper

    def initialize(type, inherited_props, user_props)
      @type = type
      # TODO: Implement priority between the properties.
      @props = user_props.merge(inherited_props)
    end

    def length
      # TODO: Implement me.
      nil
    end

    def read(s, offset)
      instance = @type.create_with_offset(s, offset, @props)
      [instance, instance.length]
    end

    #def write(s, offset, data)
      # TODO: Implement me.
    #end
  end

  class SubStreamPacket

    def self.instance(length)
      new length
    end

    def initialize(length)
      if length % 8 != 0
        raise NotImplementedError, "non-aligned substream has not been supported."
      end
      @length = length
    end

    attr_reader :length

    def read(s, offset)
      if offset % 8 != 0
        raise NotImplementedError, "non-aligned substream has not been supported."
      end
      return [LazyString.new(s, offset / 8, @length / 8), @length]
    end

  end

  class ReaderArray

    def initialize
      @array = []
      @read  = []
    end

    def [](pos)
      unless @read[pos]
        @read[pos] = true
        reader = @array[pos]
        if reader.value.nil?
          reader.read
        end
        @array[pos] = reader.value
      end
      return @array[pos]
    end

    def <<(reader)
      @array << reader
    end

  end

  class FieldReader
    
    def initialize(type, instance)
      @type = type
      @instance = instance
      @length = @type.length if @type.respond_to? :length
      @has_read = false
    end

    def props
      @instance.bitstream_properties
    end
    private :props
    
    def has_read?
      @has_read
    end

    def read
      unless @has_read
        if @offset.nil?
          index
        end
        @value, @length = @type.read(props.raw_data, @offset)
        @has_read = true
      end
      return @value
    end
    
    alias :value :read

    def length
      # @length must not be nil if @has_read.
      if @length.nil?
        if @offset.nil?
          index
        else
          @value, @length = @type.read(props.raw_data, @offset)
          @has_read = true
        end
      end
      return @length
    end

    def index
      queue = props.eval_queue
  
      while @offset.nil?
        field = queue.deq
        field.offset = props.curr_offset
        length = field.length
        props.curr_offset += length
      end
    end

    attr_accessor :offset

  end

  module ClassMethods

    def initialize_for_class_methods(types)
      @field_defs = []
      @fields = {}
      @types = types.dup
      @index = 0
      @singleton_props = {}
      @class_props = {}
      @class_props_chain = [@class_props]
      @bitstream_mutex = Mutex.new
    end

    # Currently BitStream does not support inheritance.
    if false
      def on_inherit(types, chain, fields, mutex)
        @field_defs = []
        @fields = fields
        @types = types
        @index = 0
        @class_props = {}
        @class_props_chain = [@class_props]
        @class_props_chain.concat(chain)
        @bitstream_mutex = mutex
      end
      
      def inherited(subclass)
        subclass.on_inherit(@types, @class_props_chain, @fields, @bitstream_mutex)
        def subclass.fields
          raise NameError, "Cannot define fields on a subclass of a class includes BitStream."
        end
      end
    end

    def fields(&field_def)
      @field_defs << field_def
    end

    def initialize_instance(raw_data, instance)
      props = instance.bitstream_properties
      props.mode = :field_def
      
      user_props = props.user_props
      
      @class_props_chain.each do |class_props|
        user_props.merge!(class_props)
      end
      user_props[:nest_chain] = user_props[:nest_chain] + [instance]
      
      @bitstream_mutex.synchronize do
        @instance = instance

        @field_defs.each do |field_def|
          field_def.call
        end
      end
      substream_types = @singleton_props[:substream_types]
      substreams = props.substreams
      unless substream_types.nil?
        substreams.keys.each do |id|
          # TODO: Support multi type substreams.
          substreams[id] = substream_types[0].instance.read(substreams[id])
        end
      end
    end

    def self.types
      @types
    end
    
    def self.register_types(types)
      types.each do |t|
        register_type(t, nil)
      end
    end
    
    def self.register_type(type, name = nil)
      if name.nil?
        name = Utils.class2symbol type
      end
      
      @types = {} if @types.nil?
      @types[name] = type

      add_type(type, name, self)
    end

    def self.alias_type(alias_name, aliasee)
      @types[alias_name] = @types[aliasee]
      alias_method(alias_name, aliasee)
    end

    def props
      @instance.bitstream_properties.user_props
    end

    def byte_order(order)
      @class_props[:byte_order] = order.intern
    end

    def substream_types(*types)
      @singleton_props[:substream_types] = types
    end

    def self.add_type(type, name = nil, bs = self)
      bs.instance_eval do
        define_method(name) do |*args|
          name = args.shift.intern
          #if respond_to? name
          #  raise "#{name} has already defined."
          #end
          
          props = @instance.bitstream_properties
          fields = props.fields
          queue = props.eval_queue
          user_props = props.user_props
          
          case props.mode
          when :field_def
            if type.respond_to? :read
              type_instance = type
            else
              type_instance = type.instance(user_props, *args)
            end
            field = FieldReader.new(type_instance, @instance)
            queue.enq(field)

            name_in_method = name

            @instance.singleton_class.instance_eval do
              define_method name do
                field.value
              end
            end

            instance = @instance
            singleton_class.instance_eval do
              define_method name_in_method do
                instance.send(name_in_method)
              end
            end
          end
        end
      end
    end

    def array(name, size, type_name, *type_args)
      name = name.intern
      type_name = type_name.intern
      type = @types[type_name]
      props = @instance.bitstream_properties
      queue = props.eval_queue
      user_props = props.user_props

      if type.nil?
        raise BitStreamError, "There is no type named \"#{type_name}\""
      end

      if type.respond_to? :read
        unless type_args.empty?
          raise BitStreamError, "#{type} does not accept any arguments."
        end
        type_instance = type
      else
        type_instance = type.instance(user_props, *type_args)
      end

      case props.mode
      when :field_def
        field = ArrayProxy.new(@instance)
        if size.respond_to?(:to_int) && size >= 0
          size.times do
            field_element = FieldReader.new(type_instance, @instance)
            field.add_field(field_element)
            queue.enq(field_element)
          end
        else
          queue.peek_back.index unless queue.empty?
          while props.curr_offset < props.raw_data.bytesize * 8
            field_element = FieldReader.new(type_instance, @instance)
            field.add_field(field_element)
            queue.enq(field_element)
            field_element.index
            #puts "curr_offset:#{props.curr_offset} bytesize:#{props.raw_data.bytesize}"
          end
        end

        @instance.singleton_class.instance_eval do
          define_method name do
            field
          end
        end

        name_in_method = name
        instance = @instance
        singleton_class.instance_eval do
          define_method name do
            instance.send(name_in_method)
          end
        end
      end
    end

    def dyn_array(name, type_name, *type_args)
      name = name.intern
      type_name = type_name.intern
      type = @types[type_name]
      props = @instance.bitstream_properties
      fields = props.fields
      queue = props.eval_queue
      user_props = props.user_props

      if type.nil?
        raise BitStreamError, "There is no type named \"#{type_name}\""
      end

      if type.respond_to? :read
        unless type_args.empty?
          raise BitStreamError, "#{type} does not accept any arguments."
        end
        type_instance = type
      else
        type_instance = type.instance(user_props, *type_args)
      end

      case props.mode
      when :field_def
        if fields[name].nil?
          fields[name] = ArrayProxy.new(@instance)
        end
        field = FieldReader.new(type_instance, @instance)
        fields[name].add_field(field)
        queue.enq(field)

        name_in_method = name
        
        @instance.singleton_class.instance_eval do
          define_method name do
            return fields[name_in_method]
          end
        end

        instance = @instance
        singleton_class.instance_eval do
          define_method name do
            instance.send(name_in_method)
          end
        end
      end
    end
    
    def substream(name, id, length)
      name = name.intern
      props = @instance.bitstream_properties
      user_props = props.user_props
      raw_data = props.raw_data
      queue = props.eval_queue
      top_stream = @instance.bitstream_properties.user_props[:nest_chain].first
      substreams = top_stream.bitstream_properties.substreams
      
      case props.mode
      when :field_def
        type_instance = SubStreamPacket.instance(length)
        field = FieldReader.new(type_instance, @instance)
        queue.enq(field)
        field.read
        
        substreams[id] << LazyString.new if substreams[id].empty?
        substreams[id].last << field.value
      end
    end

    def separate_substream(id)
      # TODO: Refactor here.
      top_stream = @instance.bitstream_properties.user_props[:nest_chain].first
      substreams = top_stream.bitstream_properties.substreams
      substreams[id] << LazyString.new
    end

    def add_type(type, name = nil)
      if name.nil?
        name = Utils.class2symbol(type)
      end
      @types[name] = type
      ClassMethods.add_type(type, name, self.singleton_class)
    end

    register_types [Unsigned, Signed, Cstring, String, Char]
    alias_type :unsigned_int, :unsigned
    alias_type :int, :signed

    def create(s, props = {})
      create_with_offset(s, 0, props)
    end

    def create_with_offset(s, offset, props = {})
      props[:nest_chain] = [] unless props.include?(:nest_chain)
      klass = Class.new(self)
      instance = klass.new
      instance.initialize_properties(s, offset)
      instance.bitstream_properties.user_props = props
      initialize_instance(s, instance)
      instance.initialize_with_fields
      return instance
    end

    def method_missing(name, *args)
      name_s = name.to_s
      field_name = args.shift
      if name_s =~ /^uint(\d+)$/
        bit_width = Regexp.last_match[1].to_i
        unsigned field_name, bit_width, *args
      elsif name_s =~ /^int(\d+)$/
        bit_width = Regexp.last_match[1].to_i
        signed field_name, bit_width, *args
      else
        super name, args
      end
    end

    def instance(inherited_props, user_props = {})
      NestWrapper.new(self, inherited_props, user_props)
    end
    
  end

  def self.included(obj)
    obj.extend ClassMethods
    obj.initialize_for_class_methods(ClassMethods.types)
  end

  def initialize_with_fields
    # Nothing to do.
    # Override me if you want to do anything after all fields has been defined.
  end

  def initialize_properties(s, offset = 0)
    props = Properties.new
    props.curr_offset = offset
    props.fields = {}
    props.raw_data = s
    props.initial_offset = offset
    props.eval_queue = Queue.new
    props.substreams = Hash.new do |hash, key|
      hash[key] = []
    end
    @bitstream_properties = props
  end

  def length
    props = @bitstream_properties
    queue = props.eval_queue
    queue.peek_back.index unless queue.empty?
    props.curr_offset - props.initial_offset
  end

  def substreams
    @bitstream_properties.substreams.values
  end

  #def properties=(props)
    # Method to override.
  #end

  attr_accessor :bitstream_properties

end
