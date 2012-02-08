# Author:: Natsuki Kawai (natsuki.kawai@gmail.com)
# Copyright:: Copyright 2011 Natsuki Kawai
# License:: 2-clause BSDL or Ruby's


require 'test/unit'
require 'bitstream'

class HavingProps

  include BitStream

  fields do
    unsigned_int :u1, props[:lengths][0]
    unsigned_int :u2, props[:lengths][1]
  end

end

class TestSimpleProperties < Test::Unit::TestCase

  def setup
    @spec = HavingProps.create "\x01\x02\x03\x04", lengths: [24, 8]
  end

  def test_u1
    assert_equal(0x010203, @spec.u1)
  end

  def test_u2
    assert_equal(0x04, @spec.u2)
  end

end
