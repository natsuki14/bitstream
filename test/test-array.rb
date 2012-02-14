# Author:: Natsuki Kawai (natsuki.kawai@gmail.com)
# Copyright:: Copyright (c) 2011, 2012 Natsuki Kawai
# License:: 2-clause BSDL or Ruby's


require 'test/unit'
require 'bitstream'

class ArraySample

  include BitStream

  fields do
    array :a1, 5, :unsigned_int, 16
  end

end

class InfiniteArraySample

  include BitStream

  fields do
    array :a1, nil, :uint16
  end

end

class VarlenArraySample

  include BitStream

  fields do
    array :a1, nil, :cstring
  end

end

class TestArray < Test::Unit::TestCase

  def setup
    @spec = ArraySample.create "\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a"
    @spec_inf = InfiniteArraySample.create "\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a"
    @spec_var = VarlenArraySample.create "foo\0quux\0baz\0"
  end

  def test_a1
    assert_equal(5, @spec.a1.size)
    assert_equal(0x0102, @spec.a1[0])
    assert_equal(0x0304, @spec.a1[1])
    assert_equal(0x0506, @spec.a1[2])
    assert_equal(0x0708, @spec.a1[3])
    assert_equal(0x090a, @spec.a1[4])
    assert_equal(nil, @spec.a1[5])
  end

  def test_infinite
    assert_equal(5, @spec_inf.a1.size)
    assert_equal(0x0102, @spec_inf.a1[0])
    assert_equal(0x0304, @spec_inf.a1[1])
    assert_equal(0x0506, @spec_inf.a1[2])
    assert_equal(0x0708, @spec_inf.a1[3])
    assert_equal(0x090a, @spec_inf.a1[4])
    assert_equal(nil, @spec_inf.a1[5])
  end

  def test_varlen
    assert_equal(3, @spec_var.a1.size)
    assert_equal("foo", @spec_var.a1[0])
    assert_equal("quux", @spec_var.a1[1])
    assert_equal("baz", @spec_var.a1[2])
    assert_equal(nil, @spec_var.a1[3])
  end

end
