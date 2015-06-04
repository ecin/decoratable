require "thread"

# Public: provide an easy way to define "aspects", decorations
# that add common behaviour to a method.
#
# More info on aspect-oriented programming (AOP):
# http://en.wikipedia.org/wiki/Aspect-oriented_programming
#
# Examples
#
#   module Helpers
#     extend Aspectable
#
#     def measurable(logger = STDOUT, &block)
#       start = Time.now
#       yield
#     ensure
#       duration = (Time.now - start).round(2)
#       logger.puts "#{block.source_location.join(":")} took #{duration}s to run."
#     end
#
#     def retryable(tries = 1, options = { on: [RuntimeError] } )
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
#     def debuggable
#       begin
#         yield
#       rescue
#         require "debug"
#       end
#     end
#
#     def memoizable(&block)
#       method_name, _ = block.source_location
#       key = :"@#{method_name}"
#       if defined?(key)
#         instance_variable_get key
#       else
#         instance_variable_set key, yield
#       end
#     end
#   end
#
#   class Client
#     extend Helpers
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
module Aspectable
  @@lock = Mutex.new

  def self.extended(klass)
    # This #method_added affects all methods defined in the module
    # that extends Aspectable.
    def klass.method_added(aspect_name)
      return unless @@lock.try_lock

      aspect_method = instance_method(aspect_name)

      define_method(aspect_name) do |*args, &block|
        # Wrap method_added to add aspect to the next method definition
        self.singleton_class.instance_eval do
          alias_method "method_added_without_#{aspect_name}", :method_added
        end

        define_singleton_method(:method_added) do |method_name|
          original_method = instance_method(method_name)

          decorator = Module.new do
            define_method(method_name) do |*args, &block|
              result = nil
              aspect_method.bind(self).call do
                result = original_method.bind(self).call(*args, &block)
              end
              result
            end
          end

          # Call aspect before "real" method
          prepend decorator

          # Call next method_added link in the chain
          __send__("method_added_without_#{aspect_name}", method_name)

          # Remove ourselves from method_added chain
          self.singleton_class.instance_eval do
            alias_method "method_added", "method_added_without_#{aspect_name}"
          end
        end
      end
    ensure
      @@lock.unlock if @@lock.locked?
    end
  end

end
