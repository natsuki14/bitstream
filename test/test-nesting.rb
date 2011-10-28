require 'test/unit'
require 'bitstream'

class Nested

  include BitStream

  fields do
    unsigned_int "u1", 8
    unsigned_int :u2, 8
  end

  #def length
  #  16
  #end

end

class Nesting

  include BitStream

  add_type Nested, :nested

  fields do
    unsigned_int "u1", 8
    nested       "n"
    unsigned_int :u2, 8
  end

  def length
    32
  end

end

class TestNesting < Test::Unit::TestCase

  def setup
    @spec = Nesting.create "\x01\x02\x03\x04"
  end

  def test_nesting_u1
    assert_equal(0x01, @spec.u1)
  end

  def test_nesting_u2
    assert_equal(0x04, @spec.u2)
  end

  def test_nesting
    assert_equal(32, @spec.length)
  end

  def test_nested_u1
    assert_equal(0x02, @spec.n.u1)
  end

  def test_nested_u2
    assert_equal(0x03, @spec.n.u2)
  end

  def test_nested
    assert_equal(16, @spec.n.length)
  end

end
