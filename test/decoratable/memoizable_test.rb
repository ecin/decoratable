require "test_helper"

require "decoratable/memoizable"

describe Memoizable do

  before do
    klass = Class.new do
      extend Memoizable

      memoizable
      def call
        @count ||= 0
        @count += 1
      end

      memoizable
      def scream!
        "BOO!"
      end
    end

    @object = klass.new
  end

  it "memoizes a method's return value" do
    3.times { @object.call }

    # If method was memoized, the counter shouldn't have incremented
    @object.call.must_equal 1
  end

  it "works with methods that have punctuation marks" do
    3.times { @object.scream! }
  end

end
