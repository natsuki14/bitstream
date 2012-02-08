# Author:: Natsuki Kawai (natsuki.kawai@gmail.com)
# Copyright:: Copyright (c) 2012 Natsuki Kawai
# License:: 2-clause BSDL or Ruby's

require 'test/unit'
require 'lazy-string'

class TestLazyString < Test::Unit::TestCase

  def setup
    @sample = LazyString.new
    @sample << "foo"
    @sample << "bar"
    @sample << "quux"
    @sample << "baz"
  end

  def test_head
    assert_equal("fo", @sample[0, 2].to_str)
    assert_equal("foo", @sample[0, 3].to_str)
    assert_equal("foob", @sample[0, 4].to_str)
  end

  def test_im
    assert_equal("a", @sample[4, 1].to_str)
    assert_equal("bar", @sample[3, 3].to_str)
    assert_equal("obarq", @sample[2, 5].to_str)
  end

  def test_last
    assert_equal("az", @sample[11, 2].to_str)
    assert_equal("baz", @sample[10, 3].to_str)
    assert_equal("xbaz", @sample[9, 4].to_str)
  end

end
