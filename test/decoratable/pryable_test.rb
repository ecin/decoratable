require "test_helper"

require "decoratable/pryable"

describe Pryable do

  # stub Binding#pry for test; I'm sorry
  class Binding
    @@pry_count = 0

    def self.pry_count
      @@pry_count
    end

    def pry
      @@pry_count += 1
    end
  end

  before do
    klass = Class.new do
      extend Pryable

      pryable(on: [NoMethodError, ArgumentError])
      def call
        @count ||= 0

        case @count
        when 0 then raise NoMethodError
        when 1 then raise ArgumentError
        else raise RuntimeError
        end

      ensure
        @count += 1
      end
    end

    @object = klass.new
  end

  it "enters a pry session for the specified exceptions" do
    proc { 3.times { @object.call } }.must_raise RuntimeError
    Binding.pry_count.must_equal 2
  end

end
