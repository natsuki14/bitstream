require 'random-accessible'

require 'types/integer'
require 'types/string'
require 'types/cstring'
require 'types/character'

module BitStream

  class BitStreamError < Exception
  end

  Properties = Struct.new(
    :curr_offset, :fields, :mode, :raw_data,
    :initial_offset, :user_props, :eval_queue
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
        unless field.has_read?
          BitStream.read_one_field(field, @instance)
        end
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

  module Utils

    def self.class2symbol(type)
      name = type.name.split("::").last
      name = self.camel2snake(name).intern
    end

    def self.camel2snake(camel)
      snake = camel.dup
      snake[0] = snake[0].downcase
      snake.gsub(/[A-Z]/) do |s|
        "_" + s.downcase
      end
    end

  end

  def self.read_one_field(value, instance)
    props = instance.bitstream_properties
    queue = props.eval_queue

    while value.offset.nil?
      field = queue.deq
      field.offset = props.curr_offset
      length = field.length
      length = field.decide_length if length.nil?
      props.curr_offset += length
    end
    value.read
  end
  
  def self.index_all_fields(instance)
    props = instance.bitstream_properties
    queue = props.eval_queue
    
    queue.each do |field|
      field.offset = props.curr_offset
      length = field.length
      length = field.decide_length if length.nil?
      props.curr_offset += length
    end
    queue.clear
  end
  
  class Value
    
    def initialize(type, raw_data)
      @type = type
      @raw_data = raw_data
      @length = @type.length if @type.respond_to? :length
      @has_read = false
    end

    def has_read?
      @has_read
    end

    def read
      unless @has_read
        if @offset.nil?
          raise "Has not been set offset."
        else
          @value, @length = @type.read(@raw_data, @offset)
          @has_read = true
        end
      end
      return @value
    end

    def decide_length
      # @length must not be nil if @has_read.
      if @length.nil?
        if @offset.nil?
          raise "Has not been set offset."
        else
          @value, @length = @type.read(@raw_data, @offset)
          @has_read = true
        end
      end
      return @length
    end

    attr_reader :length, :value
    attr_accessor :offset

  end

  module ClassMethods

    def initialize_for_class_methods(types)
      @field_defs = []
      @fields = {}
      @types = types.dup
      @index = 0
      @class_props = {}
      @bitstream_mutex = Mutex.new
    end

    def fields(&field_def)
      @field_defs << field_def
    end

    def initialize_instance(raw_data, instance)
      props = instance.bitstream_properties
      props.mode = :field_def
      props.user_props.merge!(@class_props)
      @bitstream_mutex.synchronize do
        @instance = instance

        @field_defs.each do |field_def|
          field_def.call
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
            field = Value.new(type_instance, props.raw_data)
            queue.enq(field)
            @instance.bitstream_properties.fields[name] = field

            name_in_method = name

            define_method name do
              field = bitstream_properties.fields[name_in_method]
              if field.value.nil?
                BitStream.read_one_field(field, self)
              end
              field.value
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
        size.times do
          field_element = Value.new(type_instance, props.raw_data)
          field.add_field(field_element)
          queue.enq(field_element)
        end

        define_method name do
          field
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
        field = Value.new(type_instance, props.raw_data)
        fields[name].add_field(field)
        queue.enq(field)

        name_in_method = name
        
        define_method name do
          return fields[name_in_method]
        end

        instance = @instance
        singleton_class.instance_eval do
          define_method name do
            instance.send(name_in_method)
          end
        end
      end
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
      klass = Class.new(self)
      instance = klass.new(s, offset)
      instance.bitstream_properties.user_props = props
      initialize_instance(s, instance)
      return instance
    end

    #def method_missing(name, *args)
      # TODO: Support methods like "int16" "uint1"
    #  super name, args
    #end

    def instance(inherited_props, user_props = {})
      NestWrapper.new(self, inherited_props, user_props)
    end
    
  end

  def self.included(obj)
    obj.extend ClassMethods
    obj.initialize_for_class_methods(ClassMethods.types)
  end

  def initialize(s, offset = 0)
    props = Properties.new
    props.curr_offset = offset
    props.fields = {}
    props.raw_data = s
    props.initial_offset = offset
    props.eval_queue = Queue.new
    @bitstream_properties = props
  end

  def length
    BitStream.index_all_fields(self)
    props = @bitstream_properties
    props.curr_offset - props.initial_offset
  end

  #def properties=(props)
    # Method to override.
  #end

  attr_accessor :bitstream_properties

end
