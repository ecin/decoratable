require "minitest/autorun"
require "minitest/pride"
require "pry"

require "aspectable"

describe Aspectable do

  module Aspects
    extend Aspectable

    def retryable(tries = 1, options = { on: [RuntimeError] } )
      attempts = 0

      begin
        yield
      rescue *options[:on]
        attempts += 1
        attempts > tries ? raise : retry
      end
    end

    def measurable(logger = STDOUT)
      current = Time.now
      yield
    ensure
      original_method = __aspected_method__
      method_location, line = original_method.source_location
      marker = "#{original_method.owner}##{original_method.name}[#{method_location}:#{line}]"
      duration = (Time.now - current).round(2)

      logger.puts "#{marker} took #{duration}s to run."
    end

    def memoizable
      key = :"@#{__aspected_method__.name}"

      if instance_variable_defined?(key)
        instance_variable_get key
      else
        instance_variable_set key, yield
      end
    end

  end

  class Plant
    extend Aspects

    def initialize
      @size = 0
    end

    @@count = 0

    retryable
    measurable
    def call
      @@count += 1
      if @@count <= 1
        sleep 1
        raise
      else
        true
      end
    end

    memoizable
    def grow(by = 1)
      @size += by
    end
  end

  it "decorates a method" do
    require "pry"
    plant = Plant.new
    plant.grow
    binding.pry
    Plant.new.call.must_equal true
  end

  it "can define more than one aspect in the same module"
  it "can use aspects in any order"
  it "passes parameters along to aspects"
  it "only decorates the next defined method"
end
