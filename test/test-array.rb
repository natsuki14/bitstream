# Author:: Natsuki Kawai (natsuki.kawai@gmail.com)
# Copyright:: Copyright 2011 Natsuki Kawai
# License:: 2-clause BSDL or Ruby's


require 'test/unit'
require 'bitstream'

class ArraySample

  include BitStream

  fields do
    array :a1, 5, :unsigned_int, 16
  end

end

class TestArray < Test::Unit::TestCase

  def setup
    @spec = ArraySample.create "\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a"
  end

  def test_a1
    assert_equal(0x0102, @spec.a1[0])
    assert_equal(0x0304, @spec.a1[1])
    assert_equal(0x0506, @spec.a1[2])
    assert_equal(0x0708, @spec.a1[3])
    assert_equal(0x090a, @spec.a1[4])
  end

end
