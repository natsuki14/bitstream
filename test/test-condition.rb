# Author:: Natsuki Kawai (natsuki.kawai@gmail.com)
# Copyright:: Copyright 2011 Natsuki Kawai
# License:: 2-clause BSDL or Ruby's


require 'test/unit'
require 'bitstream'

class ConditionSample

  include BitStream

  fields {
    unsigned_int :u1, 32
    if u1 == 0
      unsigned_int :u2, 32
    end
  }

end

class TestCondition < Test::Unit::TestCase

  def setup
  end

  def test_condition_true
    spec = ConditionSample.create "\x00\x00\x00\x00\x00\x00\x00\x01"
    assert_equal(0, spec.u1)
    assert_equal(1, spec.u2)
  end

  def test_condition_false
    spec = ConditionSample.create "\x00\x00\x00\x01\x00\x00\x00\x01"
    assert_equal(1, spec.u1)
    assert_raise(NoMethodError) do
      spec.u2
    end
  end

  def test_condition_false_with_dummy
    ConditionSample.create "\x00\x00\x00\x00\x00\x00\x00\x01" # dummy
    spec = ConditionSample.create "\x00\x00\x00\x01\x00\x00\x00\x01"
    assert_equal(1, spec.u1)
    assert_raise(NoMethodError) do
      spec.u2
    end
  end

end
