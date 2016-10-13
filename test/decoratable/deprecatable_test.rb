require "test_helper"

require "decoratable/deprecatable"
require "decoratable/retryable"
require "decoratable/memoizable"

describe Deprecatable do
  extend Memoizable

  before do
    # Need to assign to a local variable so it's accessible from
    # the following class definition scope.
    logger = mock_logger

    klass = Class.new do
      extend Deprecatable
      extend Retryable

      deprecatable(logger)
      def old_method; end
    end

    @object = klass.new
  end

  it "prints a warning when a method is called" do
    # If the `@object.old_method` line moves around, we'll have to modify the line arithmetic for the
    # expected regex.
    mock_logger.expect(:warn, nil, [/old_method is deprecated\. Called from: #{__FILE__}:#{__LINE__ + 2}/])

    @object.old_method
    mock_logger.verify
  end

  # Reusing library code in a test? Amazing!
  memoizable
  def mock_logger
    Minitest::Mock.new
  end
end
