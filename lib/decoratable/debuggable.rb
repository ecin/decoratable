require "decoratable"

module Debuggable
  extend Decoratable

  def debuggable(options = { on: [RuntimeError] })
    yield
  rescue *options[:on]
    require "debug"
  end
end
