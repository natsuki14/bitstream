require 'test/unit'
require 'types/string'

class TestString < Test::Unit::TestCase

  def test_aligned_read
    type = BitStream::String.instance({}, 3)
    val, len = type.read("foobarbaz", 16)
    assert_equal("oba", val)
    assert_equal(3 * 8, len)
  end

  def test_aligned_write
    type = BitStream::String.instance({}, 3)
    val = "foobarbaz"
    ret = type.write(val, 24, "qux")
    assert_equal("fooquxbaz", val)
  end

  def test_unaligned_read
    type = BitStream::String.instance({}, 2)
    val, len = type.read([0x12345678].pack('N'), 1)
    assert_equal("\x24\x68", val)
    assert_equal(2 * 8, len)
  end

  def test_unaligned_write
    type = BitStream::String.instance({}, 2)
    val = "\x12\x34"
    ret = type.write(val, 7, "\xcd\xef")

    assert_equal("\x13\x9b", val[0..1])
    assert(val[2].ord & 0xfe == 0xde)
  end

end
