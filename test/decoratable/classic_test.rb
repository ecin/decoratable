require "test_helper"

require "decoratable/classic"

require "logger"

describe "Decoratable: Classic Style" do
  # Test-only decorations
  module Decorations
    extend Decoratable

    def loggable(logger: Logger.new(STDOUT))
      logger.info __decorated_method__.name
    end
  end
  it "decorates a method, classic style" do
    logger = mock_logger
    klass = Class.new do
      extend Decorations

      def call; end
      loggable :call, logger: logger
    end

    object = klass.new
    3.times { object.call }
  end

  def mock_logger
    logger = Minitest::Mock.new

    # We expect info to be called thrice
    logger.expect(:info, nil, [:call])
    logger.expect(:info, nil, [:call])
    logger.expect(:info, nil, [:call])

    logger
  end

  # Remove Decoratable constant so we reset back to original
  Object.send(:remove_const, :Decoratable)
  load "decoratable.rb"
end
