require "minitest/autorun"
require "minitest/pride"

require "aspectable"

describe Aspectable do

  module Retryable
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
  end

  module Measurable
    extend Aspectable

    def measurable(logger = STDOUT)
      current = Time.now
      yield
      logger.puts "Took #{Time.now - current} to run."
    end
  end

  class Clumsy
    extend Retryable
    extend Measurable

    @@count = 0

    def self.method_added(method_name)
    end

    require "pry"

    retryable
    measurable
    def call
      @@count += 1
      if @@count <= 1
        raise
      else
        true
      end
    end

    def call2

    end
  end

  it "modifies a method" do
    binding.pry
    Clumsy.new.call.must_equal true
  end
end
