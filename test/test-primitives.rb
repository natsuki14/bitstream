require 'test/unit'
require 'bitstream'

class SimpleInt

  include BitStream

  fields {
    unsigned_int "u1", 32
    unsigned_int :u2, 32
    cstring      "cs1"
    unsigned_int "u3", 1
    unsigned_int "u4", 7
  }

end

class TestSimpleInt < Test::Unit::TestCase

  def setup
    @spec = SimpleInt.create "\x10\x20\x30\x40\x50\x60\x70\x80foobar\00\xfe\x00"
  end

  def test_u1
    assert_equal(0x10203040.to_s(16), @spec.u1.to_s(16))
  end

  def test_u2
    assert_equal(0x50607080.to_s(16), @spec.u2.to_s(16))
  end

  def test_u3
    assert_equal(1, @spec.u3)
  end

  def test_u4
    assert_equal(0x7e, @spec.u4)
  end

  def test_cs1
    assert_equal("foobar", @spec.cs1)
  end

end
