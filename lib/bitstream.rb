require 'random-accessible'

require 'types/integer'
require 'types/string'
require 'types/cstring'
require 'types/character'

module BitStream

  class BitStreamError < Exception
  end

  class Properties
    attr_accessor :curr_offset, :fields, :fibers, :mode, :raw_data, :initial_offset, :user_props, :eval_queue
  end

  class ArrayProxy

    include RandomAccessible

    def initialize(instance, bitstream_class)
      @fields = []
      @instance = instance
      @bitstream_class = bitstream_class
    end

    def add_field(field)
      @fields << field
    end

    def get_field(pos)
      @fields[pos]
    end

    def read_access(pos)
      field = @fields[pos]
      if field.value.nil?
        @instance.class.read_one_field(field, @instance)
      end
      return field.value
    end

    def write_access(pos, val)
      self
    end

    def shrink(n)
      @fields.pop(n)
    end

  end

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

  class Value

    def initialize(type, raw_data)
      @type = type
      @raw_data = raw_data
    end

    def read
      #STDERR.puts "Reading... (offset: #{@offset})"
      if @value.nil?
        if @offset.nil?
          raise "Has not been set offset."
        else
          @value, @length = @type.read(@raw_data, @offset)
        end
      end
      #STDERR.puts "Return the value \"#{@value}\""
      return @value
    end

    attr_reader :length, :value
    attr_accessor :type # For debugging.
    attr_accessor :offset

  end

  module ClassMethods

    def initialize_for_class_methods(types)
      @field_defs = []
      @field_array = []
      @fields = {}
      @types = types.dup
      @index = 0
    end

    def fields(&field_def)
      @field_defs << field_def
    end

    def initialize_instance(raw_data, instance)
      props = instance.bitspec_properties
      @field_defs.each do |field_def|
        props.fibers << Fiber.new(&field_def)
      end
      @instance = instance
      props.mode = :field_def

      @field_defs.each do |field_def|
        field_def.call
      end
    end

    def read_one_field(value, instance)
      #STDERR.puts "Try to read the field \"#{name}\""
      props = instance.bitspec_properties
      @instance = instance
      queue = props.eval_queue

      #p props.fields[name]
      while value.offset.nil?
        field = queue.deq
        field.offset = props.curr_offset
        field.read if field.length.nil?
        props.curr_offset += field.length
      end
      value.read
    end

    def index_all_fields(instance)
      props = instance.bitspec_properties
      @instance = instance
      queue = props.eval_queue
      
      queue.each do |field|
        field.offset = props.curr_offset
        field.read if field.length.nil?
        props.curr_offset += field.length
      end
      queue.clear
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
      @instance.bitspec_properties.user_props
    end

    def self.add_type(type, name = nil, bs = self)
      bs.instance_eval do
        define_method(name) do |*args|
          name = args.shift.intern
          #puts "A field (#{name}@#{type}) was called with mode #{@mode}, self #{self}, args #{args}."        
          #if respond_to? name
          #  throw "#{name} has already defined."
          #end
          
          props = @instance.bitspec_properties
          fields = props.fields
          queue = props.eval_queue
          
          case props.mode
          when :field_def
            #STDERR.puts "Generated a new value."
            #p types
            if type.respond_to? :read
              type_instance = type
            else
              type_instance = type.instance(*args)
            end
            field = Value.new(type_instance, props.raw_data)
            fields[name] = field
            queue.enq(field)
            
            #STDERR.puts "Defined field \"#{name}\""
            name_ = name
            
            define_method name do
              #STDERR.puts "Read the field \"#{name_}\""
              if fields[name_].value.nil?
                self.class.read_one_field(field, self)
              end
              #STDERR.puts "type(#{name_})=#{fields[name_].type}"
              fields[name_].value
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
      name = name.intern if name.respond_to? :intern
      type_name = type_name.intern if type_name.respond_to? :intern
      type = @types[type_name]

      if type.nil?
        raise BitStreamError, "There is no type named \"#{type_name}\""
      end

      if type.respond_to? :read
        unless type_args.empty?
          raise BitStreamError, "#{type} does not accept any arguments."
        end
        type_instance = type
      else
        type_instance = type.instance(*type_args)
      end

      props = @instance.bitspec_properties
      fields = props.fields
      queue = props.eval_queue

      name_ = name
      case props.mode
      when :field_def
        fields[name_] = ArrayProxy.new(@instance, self.class)
        size.times do
          field = Value.new(type_instance, props.raw_data)
          fields[name_].add_field(field)
          queue.enq(field)
        end

        instance = @instance

        define_method name do
          fields[name_]
        end

        singleton_class.instance_eval do
          define_method name do
            instance.send(name_)
          end
        end
      end
    end

    def dyn_array(name, type_name, *type_args)
      name = name.intern if name.respond_to? :intern
      type_name = type_name.intern if type_name.respond_to? :intern
      type = @types[type_name]

      if type.nil?
        raise BitStreamError, "There is no type named \"#{type_name}\""
      end

      if type.respond_to? :read
        unless type_args.empty?
          raise BitStreamError, "#{type} does not accept any arguments."
        end
        type_instance = type
      else
        type_instance = type.instance *type_args
      end

      props = @instance.bitspec_properties
      fields = props.fields
      queue = props.eval_queue
      name_ = name
      case props.mode
      when :field_def
        if fields[name_].nil?
          fields[name_] = []
        end
        field = Value.new(type_instance, props.raw_data)
        fields[name_] << field
        queue.enq(field)

        name_ = name
        instance = @instance
        
        define_method name do
          ret = []
          fields[name_].each do |el|
            if @bitspec_properties.mode == :field_def
              self.class.read_one_field(field, instance)
              ret << el.value
            else
              ret << el.value unless el.value.nil?
            end
          end
          return ret
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

    def create(s, *props)
      create_with_offset(s, 0, *props)
    end

    def create_with_offset(s, offset, *props)
      klass = Class.new(self)
      instance = klass.new(s, offset)
      instance.bitspec_properties.user_props = props
      initialize_instance(s, instance)
      return instance
    end

    #def method_missing(name, *args)
      # TODO: Support methods like "int16" "uint1"
    #  super name, args
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
    props.fibers = []
    props.initial_offset = offset
    props.eval_queue = Queue.new
    @bitspec_properties = props
  end

  def length
    self.class.index_all_fields(self)
    props = @bitspec_properties
    props.curr_offset - props.initial_offset
  end

  def properties=(props)
    # Method to override.
  end

  attr_accessor :bitspec_properties

end
