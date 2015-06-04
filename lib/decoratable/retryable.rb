require "decoratable"

module Retryable
  extend Decoratable

  def retryable(tries = 1, options = { on: [RuntimeError] } )
    attempts = 0

    begin
      yield
    rescue *options[:on]
      attempts += 1
      attempts > tries ? raise : retry
    end
  end
end
