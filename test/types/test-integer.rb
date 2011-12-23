require 'test/unit'
require 'types/integer'

class TestUint < Test::Unit::TestCase

  BE_PROP = { big_endian: true }

  def test_uint32_nooffset_read
    type = BitStream::UnsignedInt.instance(BE_PROP,32)
    val, len = type.read("\x01\x02\x03\x04", 0)
    assert_equal(0x01020304, val)
    assert_equal(32, len)
  end

  def test_uint32_nooffset_write
    type = BitStream::UnsignedInt.instance(BE_PROP, 32)
    val = "\xff\x00"
    type.write(val, 8, 0x01020304)
    assert_equal("\xff\x01\x02\x03\x04", val)
  end

  def test_uint32_offset4_read
    type = BitStream::UnsignedInt.instance(BE_PROP, 32)
    val, len = type.read("\xf1\x02\x03\x04\x05", 4)
    assert_equal(0x10203040.to_s(16), val.to_s(16))
    assert_equal(32, len)
  end

  def test_uint1_offset1_read
    type = BitStream::UnsignedInt.instance(BE_PROP, 1)
    val, len = type.read("\x40", 1)
    assert_equal(1, val)
    assert_equal(1, len)

    val, len = type.read("\xfd", 6)
    assert_equal(0, val)
    assert_equal(1, len)
  end

end
