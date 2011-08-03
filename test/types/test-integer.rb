require 'test/unit'
require 'types/integer'

class TestUint < Test::Unit::TestCase

  def test_uint32_nooffset_read
    type = BitStream::UnsignedInt.new(32)
    val, len = type.read("\x01\x02\x03\x04", 0)
    assert_equal(0x01020304, val)
    assert_equal(32, len)
  end

  def test_uint32_nooffset_write
    type = BitStream::UnsignedInt.new(32)
    val = "\xff\x00"
    type.write(val, 8, 0x01020304)
    assert_equal("\xff\x01\x02\x03\x04", val)
  end

  def test_uint32_offset4_read
    type = BitStream::UnsignedInt.new(32)
    val, len = type.read("\x01\x02\x03\x04\x05", 4)
    assert_equal(0x10203040, val)
    assert_equal(32, len)
  end

end
