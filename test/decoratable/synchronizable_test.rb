require "test_helper"

require "decoratable/synchronizable"

describe Synchronizable do
  before do
    klass = Class.new do
      extend Synchronizable

      attr_reader :count

      synchronizable
      def increment
        if @count.nil?
          sleep 1
          @count = 0
        else
          @count += 1
        end
      end
    end

    @object = klass.new
  end

  it "runs the method once at a time" do
    threads = 2.times.map { Thread.new { @object.increment } }
    threads.each(&:join)

    # If calls to increment aren't synchronized,
    # @object.count would be equal to 0
    @object.count.must_equal 1
  end

end

