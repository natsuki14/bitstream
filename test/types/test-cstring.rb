require 'test/unit'
require 'types/cstring'

class TestCstring < Test::Unit::TestCase

  def test_aligned_read
    type = BitStream::Cstring.new
    val, len = type.read("foobar\0baz", 16)
    assert_equal("obar", val)
    assert_equal(8 * "obar\0".size, len)
  end

end
