require 'types/integer'
require 'types/cstring'
require 'types/character'

module BitStream

  class Properties
    attr_accessor :curr_offset, :fields, :fibers, :mode, :raw_data, :initial_offset
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

    def initialize_for_class_methods
      @field_defs = []
      @field_array = []
      @fields = {}
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

    def read_one_field(name, instance)
      #STDERR.puts "Try to read the field \"#{name}\""
      props = instance.bitspec_properties
      @instance = instance
      recent_mode = props.mode
      props.mode = :read

      #p props.fields[name]
      while props.fields[name].offset.nil?
        # TODO: Add an error handler.
        begin
          #STDERR.puts "Resuming the fiber."
          props.fibers[0].resume
        rescue FiberError => e
          STDERR.puts "Caught a FiberError (#{e.to_s})."
          props.fibers.shift
        end
      end
      props.fields[name].read

      props.mode = recent_mode
    end

    def index_all_fields(instance)
      props = instance.bitspec_properties
      @instance = instance
      recent_mode = props.mode
      props.mode = :read

      until props.fibers.empty?
        begin
          props.fibers[0].resume
        rescue FiberError
          props.fibers.shift
        end
      end

      props.mode = recent_mode
    end

    def self.add_type(type, name = nil, bs = self)
      if type.respond_to?(:each)
        type.each do |t|
          #STDERR.puts "Recursive add_type (#{t})."
          add_type(t, nil, bs)
        end
        return
      end

      if name.nil?
        # Convert camel-case to underscore-separated.
        name = type.name.split("::").last
        name[0] = name[0].downcase
        name.gsub!(/[A-Z]/) do |s|
          "_" + s.downcase
        end
        name = name.intern
      end

      bs.instance_eval do
        define_method(name) do |*args|
          name = args.shift.intern
          #puts "A field (#{name}@#{type}) was called with mode #{@mode}, self #{self}, args #{args}."        
          if respond_to? name
            throw "#{name} has already defined."
          end
          
          props = @instance.bitspec_properties
          fields = props.fields
          
          case props.mode
          when :field_def
            #STDERR.puts "Generated a new value."
            #p types
            unless type.respond_to? :read
              type_instance = type.instance(*args)
            else
              type_instance = type
            end
            field = Value.new(type_instance, props.raw_data)
            fields[name] = field
            
            #STDERR.puts "Defined field \"#{name}\""
            name_ = name
            
            define_method name do
              #STDERR.puts "Read the field \"#{name_}\""
              if fields[name_].value.nil?
                self.class.read_one_field(name_, self)
              end
              #STDERR.puts "type(#{name_})=#{fields[name_].type}"
              fields[name_].value
            end
            
            @instance.class.singleton_class.instance_eval do
              define_method name do
                instance.send(name)
              end
            end
          
            #TODO: Change the name of this mode.
          when :read
            #STDERR.puts "The offset of the field #{name} is #{props.curr_offset}."
            fields[name].offset = props.curr_offset
            fields[name].read if fields[name].length.nil?
            props.curr_offset += fields[name].length
            
            #STDERR.puts "Calculate offset of the field \"#{name}\". The offset is #{fields[name].offset}"
            
            Fiber.yield
          end
        end
      end
    end
 
    def add_type(type, name = nil)
      ClassMethods.add_type(type, name, self.singleton_class)
    end

    add_type [UnsignedInt, Cstring, Char]

    def create(s, offset = 0)
      klass = Class.new(self)
      instance = klass.new(s, offset)
      initialize_instance(s, instance)
      return instance
    end

    #def method_missing(name, *args)
      # TODO: Support methods like "int16" "uint1"
    #  super name, args
    #end

    def read(s, offset)
      instance = create s, offset
      [instance, instance.length]
    end
    
    #def write(s, offset, data)
      # TODO: Implement me.
    #end
    
  end

  def self.included(obj)
    obj.extend ClassMethods
    obj.initialize_for_class_methods
  end

  def initialize(s, offset = 0)
    props = Properties.new
    props.curr_offset = offset
    props.fields = {}
    props.raw_data = s
    props.fibers = []
    props.initial_offset = offset
    @bitspec_properties = props
  end

  def length
    self.class.index_all_fields(self)
    props = @bitspec_properties
    props.curr_offset - props.initial_offset
  end

  attr_accessor :bitspec_properties

end
