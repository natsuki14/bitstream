require 'test/unit'
require 'bitstream'

class SimpleIntBe

  include BitStream

  byte_order :big_endian

  fields {
    unsigned_int "u1", 32
    unsigned_int :u2, 32
    cstring      "cs1"
    unsigned_int "u3", 1
    unsigned_int "u4", 7
    string       :s1, 3
  }

end

class SimpleIntLe

  include BitStream

  byte_order :little_endian

  fields {
    unsigned_int "u1", 32
    unsigned_int :u2, 32
    cstring      "cs1"
    unsigned_int "u3", 1
    unsigned_int "u4", 7
    string       :s1, 3
  }

end

class TestSimpleInt < Test::Unit::TestCase

  def setup
    @spec = SimpleIntBe.create "\x10\x20\x30\x40\x50\x60\x70\x80foobar\00\xfebazdummy"

    # dummy
    dummy = SimpleIntBe.create "\x10\x20\x30\x40\x50\x60\x70\x80foobar\00\xfebazdummy"

    @spec_le = SimpleIntLe.create "\x10\x20\x30\x40\x50\x60\x70\x80foobar\00\xfebazdummy"
  end

  def test_u1
    assert_equal(0x10203040.to_s(16), @spec.u1.to_s(16))
  end
  def test_u1le
    assert_equal(0x40302010.to_s(16), @spec_le.u1.to_s(16))
  end

  def test_u2
    assert_equal(0x50607080.to_s(16), @spec.u2.to_s(16))
  end
  def test_u2le
    assert_equal(0x80706050.to_s(16), @spec_le.u2.to_s(16))
  end

  def test_u3
    assert_equal(1, @spec.u3)
  end
  def test_u3le
    assert_equal(1, @spec_le.u3)
  end

  def test_u4
    assert_equal(0x7e, @spec.u4)
  end
  def test_u4le
    assert_equal(0x7e, @spec_le.u4)
  end

  def test_cs1
    assert_equal("foobar", @spec.cs1)
    assert_equal("foobar", @spec_le.cs1)
  end

  def test_s1
    assert_equal("baz", @spec.s1)
    assert_equal("baz", @spec_le.s1)
  end

end
