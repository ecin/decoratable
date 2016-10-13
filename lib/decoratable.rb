require "thread"

# Public: provide an easy way to define decorations
# that add common behaviour to a method.
#
# More info on decorations as implemented in Python:
# http://en.wikipedia.org/wiki/Python_syntax_and_semantics#Decorators
#
# Examples
#
#   module Decorations
#     extend Decoratable
#
#     def retryable(tries = 1, options = { on: [RuntimeError] })
#       attempts = 0
#
#       begin
#         yield
#       rescue *options[:on]
#         attempts += 1
#         attempts > tries ? raise : retry
#       end
#     end
#
#     def measurable(logger = STDOUT)
#       start = Time.now
#       yield
#     ensure
#       original_method = __decorated_method__
#       method_location, line = original_method.source_location
#       marker = "#{original_method.owner}##{original_method.name}[#{method_location}:#{line}]"
#       duration = (Time.now - start).round(2)
#
#       logger.puts "#{marker} took #{duration}s to run."
#     end
#
#     def debuggable
#       begin
#         yield
#       rescue => e
#         puts "Caught #{e}!!!"
#         require "debug"
#       end
#     end
#
#     def memoizable
#       key = :"@#{__decorated_method__.name}_cache"
#
#       instance_variable_set(key, {}) unless defined?(key)
#       cache = instance_variable_get(key)
#
#       if cache.key?(__args__)
#         cache[__args__]
#       else
#         cache[__args__] = yield
#       end
#     end
#   end
#
#   class Client
#     extend Decorations
#
#     # Let's keep track of how long #get takes to run,
#     # and memoize the return value
#     measurable
#     memoizable
#     def get
#       …
#     end
#
#     # Rescue and retry any Timeout::Errors, up to 5 times
#     retryable 5, on: [Timeout::Error]
#     def post
#       …
#     end
#   end
module Decoratable
  @@lock = Mutex.new

  def self.extended(klass)
    # This #method_added affects all methods defined in the module
    # that extends Decoratable.
    def klass.method_added(decoration_name)
      return unless @@lock.try_lock

      decoration_method = instance_method(decoration_name)

      define_method(decoration_name) do |*decorator_args|
        # Wrap method_added to decorate the next method definition.
        self.singleton_class.instance_eval do
          alias_method "method_added_without_#{decoration_name}", :method_added
        end

        unless method_defined?(:__original_caller__)
          define_method(:__original_caller__) { @__original_caller__ }
        end

        unless method_defined?(:__decorated_method__)
          define_method(:__decorated_method__) { @__decorated_method__ }
        end

        unless method_defined?(:__args__)
          define_method(:__args__) { @__args__ }
        end

        unless method_defined?(:__block__)
          define_method(:__block__) { @__block__ }
        end

        # This method_added will affect the next decorated method.
        define_singleton_method(:method_added) do |method_name|

          original_method = instance_method(method_name)

          decoration = Module.new do
            self.singleton_class.instance_eval do
              define_method(:name) do
                "Decoratable::#{decoration_name}(#{method_name})"
              end

              alias_method :inspect, :name
              alias_method :to_s, :name
            end

            define_method(method_name) do |*args, &block|
              begin
                # The decoration should have access to the original
                # method it's modifying, along with the method call's
                # arguments.
                @__decorated_method__ = original_method
                @__args__ = args
                @__block__ = block
                @__original_caller__ ||= caller

                decoration_method.bind(self).call(*decorator_args) do
                  super(*args, &block)
                end
              ensure
                @__decorated_method__ = nil
                @__args__ = nil
                @__block__ = nil
                @__original_caller__ = nil
              end
            end
          end

          # Call aspect before "real" method.
          prepend decoration

          # Call next method_added link in the chain.
          __send__("method_added_without_#{decoration_name}", method_name)

          # Remove ourselves from method_added chain.
          self.singleton_class.instance_eval do
            alias_method :method_added, "method_added_without_#{decoration_name}"
            remove_method  "method_added_without_#{decoration_name}"
          end
        end
      end
    ensure
      @@lock.unlock if @@lock.locked?
    end
  end

end
