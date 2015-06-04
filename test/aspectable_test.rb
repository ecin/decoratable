require "minitest/autorun"
require "minitest/pride"

require "aspectable"

describe Aspectable do

  module Decorators
    extend Aspectable

    def retryable(tries = 1)
      attempts = 0

      begin
        yield
      rescue
        attempts += 1
        attempts > tries ? raise : retry
      end
    end

    def debuggable
      require "pry"
      binding.pry
      yield
    end

    def measurable(logger = STDOUT)
      current = Time.now
      yield
    ensure
      method_name = caller_locations(1,1)[0].label
      duration = (Time.now - current).round(2)
      logger.puts "Took #{duration}s to run."
    end
  end

  class Clumsy
    extend Decorators

    @@count = 0

    retryable
    measurable
    debuggable
    def call(arg)
      @@count += 1
      if @@count <= 1
        sleep 2
        raise
      else
        true
      end
    end

    def call2

    end
  end

  it "decorates a method" do
    require "pry"
    binding.pry
    Clumsy.new.call.must_equal true
  end

  it "can define more than one aspect in the same module"
  it "can use aspects in any order"
  it "passes parameters along to aspects"
  it "only decorates the next defined method"
end
