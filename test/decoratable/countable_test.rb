require "test_helper"

require "decoratable/countable"

describe Countable do

  before do
    klass = Class.new do
      extend Countable

      countable
      def call; end
    end

    @object = klass.new
  end

  it "keeps count of how many times a method is called" do
    3.times { @object.call }
    @object.call_call_count.must_equal 3
  end
end
