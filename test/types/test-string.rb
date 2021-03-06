# Author:: Natsuki Kawai (natsuki.kawai@gmail.com)
# Copyright:: Copyright 2011, 2012 Natsuki Kawai
# License:: 2-clause BSDL or Ruby's


require 'test/unit'
require 'types/string'

class TestString < Test::Unit::TestCase

  def test_aligned_read
    type = BitStream::String.instance({}, 3)
    info = type.read("foobarbaz", 16)
    assert_equal("oba", info[:value])
    assert_equal(3 * 8, info[:length])
  end

  def test_aligned_write
    type = BitStream::String.instance({}, 3)
    val = "foobarbaz"
    ret = type.write(val, 24, "qux")
    assert_equal("fooquxbaz", val)
  end

  def test_unaligned_read
    type = BitStream::String.instance({}, 2)
    info = type.read([0x12345678].pack('N'), 1)
    assert_equal("\x24\x68", info[:value])
    assert_equal(2 * 8, info[:length])
  end

  def test_unaligned_write
    type = BitStream::String.instance({}, 2)
    val = "\x12\x34"
    ret = type.write(val, 7, "\xcd\xef")

    assert_equal("\x13\x9b", val[0..1])
    assert(val[2].ord & 0xfe == 0xde)
  end

end
