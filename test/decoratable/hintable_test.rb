require "test_helper"

require "decoratable/hintable"

describe Hintable do

  before do
    klass = Class.new do
      extend Hintable

      hintable(Integer, require_block: true)
      def call(a); end
    end

    @object = klass.new
  end

  it "checks argument types" do
    proc { @object.call(:a) }.must_raise ArgumentError, /#{Regexp.escape("a expected argument of type Integer, was Symbol (:a)")}/
  end

  it "checks for a required block" do
    proc { @object.call(1) }.must_raise ArgumentError, /call requires a block/
  end

  it "steps out of the way for the correct arguments" do
    @object.call(1) { }
  end
end
