require "minitest/autorun"
require "minitest/mock"
require "minitest/pride"
require "pry"

require "decoratable"
require "logger"

describe Decoratable do

  module Decorations
    extend Decoratable

    # Not used in test
    def disable(disabled = proc { true } )
      disabled.call ? nil : yield
    end

    # Not used in tests
    def debuggable
      yield
    rescue
      binding.pry
    end

    # Not used in tests
    def retryable(tries = 1, options = { on: [RuntimeError] } )
      attempts = 0

      begin
        yield
      rescue *options[:on]
        attempts += 1
        attempts > tries ? raise : retry
      end
    end

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

    def memoizable
      key = :"@#{__decorated_method__.name}_cache"

      if instance_variable_defined?(key)
        instance_variable_get key
      else
        instance_variable_set key, yield
      end
    end

    def countable
      key = :"@#{__decorated_method__.name}_count"

      count = instance_variable_get(key).to_i
      instance_variable_set(key, count + 1)

      yield
    end

    def auditable
      name = __decorated_method__.name

      key = :"@audit_log"
      audit_log = instance_variable_get(key) || []
      audit_log << name
      instance_variable_set(key, audit_log)

      yield
    end

    def hintable(*classes, require_block: false)
      argument_names = __decorated_method__.parameters.map { |(_, param)| param }
      checks = __args__.zip(classes, argument_names)

      # check args for types
      failed_check = checks.find { |arg, klass, _| !arg.is_a?(klass) }
      if failed_check
        raise ArgumentError, "#{failed_check[2]} expected argument of type #{failed_check[1]}, was #{failed_check[0].class} (#{failed_check[0].inspect})"
      end

      if require_block && __block__.nil?
        raise ArgumentError, "#{__decorated_method__.name} requires a block"
      end

      yield
    end

  end

  it "decorates a method" do
    klass = Class.new do
      extend Decorations

      attr_reader :call_count

      countable
      def call; end
    end

    object = klass.new
    3.times { object.call }
    object.call_count.must_equal 3
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

      attr_reader :call_count

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
    object.call_count.must_equal 3

    # Check memoizable() works
    object.call.must_equal 1
  end

  it "only decorates the next defined method" do
    klass = Class.new do
      extend Decorations

      attr_reader :call_count, :call2_count

      countable
      def call; end
      def call2; end
    end

    object = klass.new
    3.times { object.call }
    3.times { object.call2 }

    object.call_count.must_equal 3
    object.call2_count.must_equal nil
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
    logger.expect(:info, nil) do |message|
      message =~ /took \d+\.\d+s to run/
    end
    logger
  end
end
