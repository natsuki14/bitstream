require 'test/unit'
require 'bitstream'

class SimpleInt

  include BitStream

  fields {
    unsigned_int "foo", 32
    unsigned_int :bar, 32
  }

end

class TestSimpleInt < Test::Unit::TestCase

  def setup
    @spec = SimpleInt.create "\x10\x20\x30\x40\x50\x60\x70\x80"
  end

  def test_foo
    STDERR.puts "Start test_foo"
    @spec.foo
    @spec.bar
    assert_equal(0x10203040, @spec.foo, "<0x%x> expected but was <0x%x>" % [0x10203040, @spec.foo])
  end

  def test_bar
    STDERR.puts "Start test_bar"
    assert_equal(0x50607080, @spec.bar, "<0x%x> expected but was <0x%x>" % [0x50607080, @spec.bar])
  end

end
