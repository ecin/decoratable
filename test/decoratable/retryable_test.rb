require "test_helper"

require "decoratable/retryable"

describe Retryable do

  before do
    klass = Class.new do
      extend Retryable

      retryable(3, on: [RuntimeError, ArgumentError])
      def call
        @count ||= 0

        case @count
        when 0 then raise RuntimeError
        when 1 then raise ArgumentError
        when 2 then raise NoMethodError
        else raise NameError
        end
      ensure
        @count += 1
      end

      retryable(3, on: RuntimeError, backoff: Retryable::LINEAR_BACKOFF)
      def call_with_backoff
        raise RuntimeError
      end

      # Stub sleep
      def sleep(seconds = nil)
        @calls ||= []

        seconds.nil? ? @calls : @calls.push(seconds)
      end
    end

    @object = klass.new
  end

  it "retries a specific number of times on specific errors" do
    proc { @object.call }.must_raise NoMethodError
  end

  it "supports custom backoff algorithms" do
    proc { @object.call_with_backoff }.must_raise RuntimeError
    @object.sleep.must_equal [1, 2, 3]
  end

end
