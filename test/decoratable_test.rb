require "minitest/autorun"
require "minitest/pride"
require "pry"

require "decoratable"

describe Decoratable do

  module Decorations
    extend Decoratable

    def override
      binding.pry
    end

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
      original_method = __decorated_method__
      method_location, line = original_method.source_location
      marker = "#{original_method.owner}##{original_method.name}[#{method_location}:#{line}]"
      duration = (Time.now - current).round(2)

      logger.puts "#{marker} took #{duration}s to run."
    end

    def memoizable
      key = :"@#{__decorated_method__.name}"

      if instance_variable_defined?(key)
        instance_variable_get key
      else
        instance_variable_set key, yield
      end
    end

    def inspectable(logger = STDOUT)
      puts
      puts "*" * 80
      puts __args__
      puts __block__
      puts "*" * 80
      puts
      yield
    end

  end

  class Plant
    extend Decorations

    inspectable
    def initialize(a = 5)
      @size = 0
      @called = 0
    end

    override
    def call
      @called += 1
      if @called <= 1
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
    skip
    plant = Plant.new
    plant.grow
    Plant.new.call.must_equal true
  end

  it "can define more than one decoration in the same module"
  it "can use decorations in any order"
  it "only decorates the next defined method"
  it "allows access to the original decorated method"
  it "can decorate initialize" do
    Plant.new(6) { puts "YAY" }
  end
  it "gives access to the arguments and blocks of the original method call"
end
