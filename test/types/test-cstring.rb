# Author:: Natsuki Kawai (natsuki.kawai@gmail.com)
# Copyright:: Copyright 2011, 2012 Natsuki Kawai
# License:: 2-clause BSDL or Ruby's


require 'test/unit'
require 'types/cstring'

class TestCstring < Test::Unit::TestCase

  def test_aligned_read
    type = BitStream::Cstring.instance({})
    info = type.read("foobar\0baz", 16)
    assert_equal("obar", info[:value])
    assert_equal(8 * "obar\0".size, info[:length])
  end

end
