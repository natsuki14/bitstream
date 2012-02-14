# Author:: Natsuki Kawai (natsuki.kawai@gmail.com)
# Copyright:: Copyright 2011, 2012 Natsuki Kawai
# License:: 2-clause BSDL or Ruby's


require 'test/unit'
require 'types/integer'

class TestUint < Test::Unit::TestCase

  BE_PROP = { :byte_order => :big_endian }
  LE_PROP = { :byte_order => :little_endian }

  def test_uint32be_nooffset_read
    type = BitStream::Unsigned.instance(BE_PROP,32)
    info = type.read("\x01\x02\x03\x04", 0)
    assert_equal(0x01020304, info[:value])
    assert_equal(32, info[:length])
  end

  def test_uint32le_nooffset_read
    type = BitStream::Unsigned.instance(LE_PROP,32)
    info = type.read("\x01\x02\x03\x04", 0)
    assert_equal(0x04030201, info[:value])
    assert_equal(32, info[:length])
  end

  def test_sint32be_nooffset_read
    type = BitStream::Signed.instance(BE_PROP,32)
    info = type.read("\xfe\xfd\xfc\xfb", 0)
    assert_equal(-0x01020304 - 1, info[:value])
    assert_equal(32, info[:length])
  end

  def test_sint32le_nooffset_read
    type = BitStream::Signed.instance(LE_PROP,32)
    info = type.read("\xfe\xfd\xfc\xfb", 0)
    assert_equal(-0x04030201 - 1, info[:value])
    assert_equal(32, info[:length])
  end

  def test_uint32_nooffset_write
    type = BitStream::Unsigned.instance(BE_PROP, 32)
    val = "\xff\x00"
    type.write(val, 8, 0x01020304)
    assert_equal("\xff\x01\x02\x03\x04", val)
  end

  def test_uint32be_offset4_read
    type = BitStream::Unsigned.instance(BE_PROP, 32)
    info = type.read("\xf1\x02\x03\x04\x05", 4)
    assert_equal(0x10203040.to_s(16), info[:value].to_s(16))
    assert_equal(32, info[:length])
  end

  def test_uint32be_offset1_read
    type = BitStream::Unsigned.instance(BE_PROP, 32)
    info = type.read("\x12\x23\x34\x45\x56", 1)
    assert_equal(0x2446688a.to_s(16), info[:value].to_s(16))
    assert_equal(32, info[:length])
  end

  def test_uint32le_offset4_read
    type = BitStream::Unsigned.instance(LE_PROP, 32)
    info = type.read("\xf1\x02\x03\x04\x05", 4)
    assert_equal(0x5040302f.to_s(16), info[:value].to_s(16))
    assert_equal(32, info[:length])
  end

  def test_uint32le_offset1_read
    type = BitStream::Unsigned.instance(LE_PROP, 32)
    info = type.read("\x80\x23\x34\x45\x56", 1)
    assert_equal(0xac8a6847.to_s(16), info[:value].to_s(16))
    assert_equal(32, info[:length])
  end

  def test_uint1be_read
    type = BitStream::Unsigned.instance(BE_PROP, 1)
    info = type.read("\x40", 1)
    assert_equal(1, info[:value])
    assert_equal(1, info[:length])

    info = type.read("\xfd", 6)
    assert_equal(0, info[:value])
    assert_equal(1, info[:length])
  end

  def test_uint1le_read
    type = BitStream::Unsigned.instance(LE_PROP, 1)
    info = type.read("\x40", 1)
    assert_equal(1, info[:value])
    assert_equal(1, info[:length])

    info = type.read("\xfd", 6)
    assert_equal(0, info[:value])
    assert_equal(1, info[:length])
  end
end
