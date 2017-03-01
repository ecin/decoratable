require "decoratable"

module Retryable
  extend Decoratable

  NO_BACKOFF = proc { 0 }
  LINEAR_BACKOFF = proc { |n| n + 1 }
  EXPONENTIAL_BACKOFF = proc { |n| 2**n }

  def retryable(tries = 1, on: [RuntimeError], backoff: NO_BACKOFF)
    attempts = 0
    on = Array(on)

    begin
      yield
    rescue *on

      if attempts >= tries
        raise
      else
        sleep backoff.call(attempts)
        attempts += 1
        retry
      end
    end
  end
end
