require "decoratable"

module Synchronizable
  extend Decoratable

  @@locks = {}
  @@locks_lock = Mutex.new

  def synchronizable(lock: Mutex.new)
    @@locks_lock.synchronize do
      lock = @@locks[__decorated_method__.source_location] ||= lock
    end

    lock.synchronize do
      yield
    end
  end
end
