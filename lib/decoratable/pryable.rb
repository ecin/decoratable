require "decoratable"

module Pryable
  extend Decoratable

  def pryable(options = { on: [RuntimeError] })
    yield
  rescue *options[:on]
    require "pry"
    binding.pry
  end
end
