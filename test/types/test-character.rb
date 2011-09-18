require 'test/unit'
require 'types/character'

class TestUint < Test::Unit::TestCase

  def test_char_nooffset_read
    type = BitStream::Char
    val, len = type.read("abcd", 8)
    assert_equal("b", val)
    assert_equal(8, len)
  end
  
end

