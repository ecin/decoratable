require "decoratable"

module Hintable
  extend Decoratable

  def hintable(*classes, require_block: false)
    argument_names = __decorated_method__.parameters.map { |(_, param)| param }
    checks = __args__.zip(classes, argument_names)

    # check args for types
    failed_check = checks.find { |arg, klass, _| !arg.is_a?(klass) }
    if failed_check
      raise ArgumentError, "#{failed_check[2]} expected argument of type #{failed_check[1]}, was #{failed_check[0].class} (#{failed_check[0].inspect})"
    end

    if require_block && __block__.nil?
      raise ArgumentError, "#{__decorated_method__.name} requires a block"
    end

    yield
  end
end
