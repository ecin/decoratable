require "decoratable"

module Memoizable
  extend Decoratable

  MEMOIZABLE_CACHE_KEY = :"@memoizable_cache"

  def memoizable
    if instance_variable_defined?(MEMOIZABLE_CACHE_KEY)
      cache = instance_variable_get(MEMOIZABLE_CACHE_KEY)
    else
      cache = instance_variable_set(MEMOIZABLE_CACHE_KEY, Hash.new)
    end

    key = __decorated_method__.name.to_sym

    if cache.has_key?(key)
      cache[key]
    else
      cache[key] = yield
    end
  end
end
