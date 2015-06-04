require "decoratable"

module Memoizable
  extend Decoratable

  def memoizable
    key = :"@#{__decorated_method__.name}_cache"

    if instance_variable_defined?(key)
      instance_variable_get key
    else
      instance_variable_set key, yield
    end
  end
end
