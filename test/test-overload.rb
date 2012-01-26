# Author:: Natsuki Kawai (natsuki.kawai@gmail.com)
# Copyright:: Copyright 2012 Natsuki Kawai
# License:: 2-clause BSDL or Ruby's

require 'test/unit'
require 'bitstream'

class OverloadSample1

  include BitStream

  fields do
    unsigned :a, 32
    unsigned :a, 32
  end

end

class OverloadSample2

  include BitStream

  fields do
    unsigned :a, 8
    if a == 1
      cstring :a
    else
      string :a, 1
    end
  end

end

class OverloadSampleArray

  include BitStream

  fields do
    array :a, 3, :unsigned, 8
    unsigned :a, 16
    unsigned :b, 16
    array :b, 2, :unsigned, 8
  end

end

class TestOverload < Test::Unit::TestCase

  def setup
    @spec1 = OverloadSample1.create "\x00\x00\x00\x01\x00\x00\x00\x02"
    @spec2 = OverloadSample2.create "\x01foo\0"
    @spec_array = OverloadSampleArray.create "abc\x01\x01\x02\x02\x03\x03"
  end

  def test_a1
    assert_equal(2, @spec1.a)
  end

  def test_a2
    assert_equal("foo", @spec2.a)
  end

  def test_array
    assert_equal(0x0101, @spec_array.a)
    assert_equal([3, 3], @spec_array.b)
  end

end

