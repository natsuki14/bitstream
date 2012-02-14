# Author:: Natsuki Kawai (natsuki.kawai@gmail.com)
# Copyright:: Copyright 2011, 2012 Natsuki Kawai
# License:: 2-clause BSDL or Ruby's


require 'test/unit'
require 'types/character'

class TestUint < Test::Unit::TestCase

  def test_char_nooffset_read
    type = BitStream::Char.instance({})
    info = type.read("abcd", 8)
    assert_equal("b", info[:value])
    assert_equal(8, info[:length])
  end
  
end

