require "thread"
# TODO: declare new method_addeds as private
module Aspectable
  @@lock = Mutex.new

  def self.extended(klass)
    def klass.method_added(aspect_name)
      # Module level, where we define a method that acts like an aspect
      return unless @@lock.try_lock

      aspect = instance_method(aspect_name)

      define_method(aspect_name) do |*args, &block|
        # Wrap method_added to add aspect to the next method definition
        self.singleton_class.instance_eval do
          alias_method "method_added_without_#{aspect_name}", :method_added
        end

        define_singleton_method(:method_added) do |method_name|
          original_method = instance_method(method_name)

          # Prepend aspect
          decorator = Module.new do
            define_method(method_name) do |*args, &block|
              result = nil
              aspect.bind(self).call { result = original_method.bind(self).call(*args, &block) }
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
