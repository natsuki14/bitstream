require 'test/unit'
require 'bitstream'

class DynArraySample

  include BitStream

  fields {
    dyn_array :a1, :char
    while a1.last != "\0"
      dyn_array :a1, :char
    end
  }

end


class TestDynArray < Test::Unit::TestCase

  def setup
    @spec = DynArraySample.create "foobar\0"
  end

  def test_a1
    assert_equal("foobar\0", @spec.a1.join)
  end

end

