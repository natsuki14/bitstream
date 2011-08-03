require 'test/unit'
require 'types/integer'

class TestUint < Test::Unit::TestCase

  def test_uint32_nooffset_read
    type = BitStream::UnsignedInt.new(32)
    val, len = type.read("\x01\x02\x03\x04", 0)
    assert_equal(0x01020304, val)
  end

  def test_uint32_nooffset_write
    type = BitStream::UnsignedInt.new(32)
    val = "0xff0x00"
    type.write(val, 8, 0x01020304)
    assert_equal("\0xffx01\x02\x03\x04", val)
  end

end
