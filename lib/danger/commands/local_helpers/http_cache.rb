require "pstore"

module Danger
  class HTTPCache
    attr_reader :expires_in
    def initialize(cache_file = nil, options = {})
      File.delete(cache_file) if options[:clear_cache]
      @store = PStore.new(cache_file)
      @expires_in = options[:expires_in] || 300 # 5 minutes
    end

    def read(key)
      @store.transaction do
        entry = @store[key]
        return nil unless entry
        return entry[:value] unless entry_has_expired(entry, @expires_in)
        @store.delete key
        return nil
      end
    end

    def delete(key)
      @store.transaction { @store.delete key }
    end

    def write(key, value)
      @store.transaction do
        @store[key] = { updated_at: Time.now.to_i, value: value }
      end
    end

    def entry_has_expired(entry, ttl)
      Time.now.to_i > entry[:updated_at].to_i + ttl.to_i
    end
  end
end
