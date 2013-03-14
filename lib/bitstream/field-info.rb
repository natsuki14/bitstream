class FieldInfo < Hash

	def initialize(value, length)
		@table = {}
		@table[:value] = value
		@table[:length] = length
	end

	def [](key)
		@table[key]
	end

end
