require "decoratable"

module Countable
  extend Decoratable

  module Helper
    def define_reader(object, key)
      unless object.respond_to?(key)
        object.define_singleton_method(key) { instance_variable_get(:"@#{key}") }
      end
    end

    module_function :define_reader
  end

  def countable
    key = :"#{__decorated_method__.name}_call_count"
    Helper.define_reader(self, key)

    instance_variable = :"@#{key}"
    count = instance_variable_get(instance_variable).to_i
    instance_variable_set(instance_variable, count + 1)

    yield
  end
end
