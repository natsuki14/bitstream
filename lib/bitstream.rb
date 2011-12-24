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
    #STDERR.puts "Try to read the field \"#{name}\""
    props = instance.bitstream_properties
    queue = props.eval_queue

    #p props.fields[name]
    while value.offset.nil?
      field = queue.deq
      field.offset = props.curr_offset
      length = field.length
      length = field.decide_length if length.nil?
      props.curr_offset += field.length
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
      #STDERR.puts "Reading... (offset: #{@offset})"
      unless @has_read
        if @offset.nil?
          raise "Has not been set offset."
        else
          @value, @length = @type.read(@raw_data, @offset)
          @has_read = true
        end
      end
      #STDERR.puts "Return the value \"#{@value}\""
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
    attr_accessor :type # For debugging.
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
          #puts "A field (#{name}@#{type}) was called with mode #{@mode}, self #{self}, args #{args}."        
          #if respond_to? name
          #  throw "#{name} has already defined."
          #end
          
          props = @instance.bitstream_properties
          fields = props.fields
          queue = props.eval_queue
          user_props = props.user_props
          
          case props.mode
          when :field_def
            #STDERR.puts "Generated a new value."
            #p types
            if type.respond_to? :read
              type_instance = type
            else
              type_instance = type.instance(user_props, *args)
            end
            field = Value.new(type_instance, props.raw_data)
            queue.enq(field)
            @instance.bitstream_properties.fields[name] = field

            #STDERR.puts "Defined field \"#{name}\""
            name_ = name

            define_method name do
              field = bitstream_properties.fields[name_]
              #STDERR.puts "Read the field \"#{name_}\""
              if field.value.nil?
                BitStream.read_one_field(field, self)
              end
              #STDERR.puts "type(#{name_})=#{fields[name_].type}"
              field.value
            end

            instance = @instance
            singleton_class.instance_eval do
              define_method name_ do
                instance.send(name_)
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

      name_ = name
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

        instance = @instance
        singleton_class.instance_eval do
          define_method name do
            instance.send(name_)
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

      name_ = name
      case props.mode
      when :field_def
        if fields[name_].nil?
          fields[name_] = ArrayProxy.new(@instance)
        end
        field = Value.new(type_instance, props.raw_data)
        fields[name_].add_field(field)
        queue.enq(field)

        name_ = name
        
        define_method name do
          return fields[name_]
        end

        instance = @instance
        singleton_class.instance_eval do
          define_method name do
            instance.send(name_)
          end
        end
      end
    end

    def add_type(type, name = nil)
      if name.nil?
        name = Utils.class2symbol(type)
      end
      puts "Add #{type.name} as #{name}"
      @types[name] = type
      ClassMethods.add_type(type, name, self.singleton_class)
    end

    register_types [UnsignedInt, Cstring, String, Char]
    alias :unsigned :unsigned_int

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

    #def instance(props)
    #  NestWrapper.new(self, props)
    #end

    def read(s, offset)
      instance = create_with_offset(s, offset)
      [instance, instance.length]
    end
    
    #def write(s, offset, data)
      # TODO: Implement me.
    #end
    
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

  def properties=(props)
    # Method to override.
  end

  attr_accessor :bitstream_properties

end
