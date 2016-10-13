require "decoratable"

require "logger"

module Deprecatable
  extend Decoratable

  def deprecatable(logger = Logger.new(STDOUT))
    logger.warn("#{__decorated_method__.name} is deprecated. Called from: #{__original_caller__[0]}")
    yield
  end
end
