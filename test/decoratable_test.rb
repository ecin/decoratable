require "test_helper"

require "decoratable"
require "decoratable/memoizable"
require "decoratable/countable"
require "decoratable/hintable"

require "logger"

describe Decoratable do

  # Test-only decorations
  module Decorations
    extend Decoratable

    include Countable
    include Hintable
    include Memoizable

    def measurable(logger = Logger.new(STDOUT))
      current = Time.now
      yield
    ensure
      original_method = __decorated_method__
      method_location, line = original_method.source_location
      marker = "#{original_method.owner}##{original_method.name}[#{method_location}:#{line}]"
      duration = (Time.now - current).round(2)

      logger.info "#{marker} took #{duration}s to run."
    end

    def auditable
      name = __decorated_method__.name

      key = :"@audit_log"
      audit_log = instance_variable_get(key) || []
      audit_log << name
      instance_variable_set(key, audit_log)

      yield
    end
  end

  it "decorates a method" do
    klass = Class.new do
      extend Decorations

      countable
      def call; end
    end

    object = klass.new
    3.times { object.call }
    object.call_call_count.must_equal 3
  end

  it "can pass configuration arguments to the decoration" do
    logger = mock_logger
    klass = Class.new do
      extend Decorations

      measurable(logger)
      def initialize; end
    end

    klass.new
    logger.verify
  end

  it "can have multiple decorations on a method" do
    klass = Class.new do
      extend Decorations

      countable
      memoizable
      def call
        @counter ||= 0
        @counter += 1
      end
    end

    object = klass.new
    3.times { object.call }

    # Check countable() works
    object.call_call_count.must_equal 3

    # Check memoizable() works
    object.call.must_equal 1
  end

  it "only decorates the next defined method" do
    klass = Class.new do
      extend Decorations

      attr_reader :call2_call_count

      countable
      def call; end
      def call2; end
    end

    object = klass.new
    3.times { object.call }
    3.times { object.call2 }

    object.call_call_count.must_equal 3
    object.call2_call_count.must_equal nil
  end

  it "allows access to the original decorated method" do
    klass = Class.new do
      extend Decorations

      attr_reader :audit_log

      auditable
      def initialize; end

      auditable
      def call; end
    end

    object = klass.new
    object.call
    object.audit_log.must_equal [:initialize, :call]
  end

  it "gives access to the arguments and blocks of the original method call" do
    klass = Class.new do
      extend Decorations

      hintable(Integer, String, require_block: true)
      def call(a, b); end
    end

    object = klass.new
    proc { object.call(:a, 1) }.must_raise ArgumentError, /#{Regexp.escape("a expected argument of type Integer, was Symbol (:a)")}/
    proc { object.call(1, :b) }.must_raise ArgumentError, /#{Regexp.escape("b expected argument of type String, was Symbol (:b)")}/
    proc { object.call(1, "") }.must_raise ArgumentError, /call requires a block/
  end

  def mock_logger
    logger = Minitest::Mock.new
    logger.expect(:info, nil, [/took \d+\.\d+s to run/])
    logger
  end
end
