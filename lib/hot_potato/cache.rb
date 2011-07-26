module HotPotato
  
  class Cache
    
    include HotPotato::Core
    
    def initialize
      log.info "Initializing connection to Redis (#{config['redis_hostname']}:#{config['redis_port']})"
      @@redis ||= Redis.new :host => config['redis_hostname'], :port => config['redis_port']
    end
    
    def get(k)
      @@redis.get(k)
    end
    
    def set(k, v, ttl = nil)
      @@redis.multi do
        @@redis.set(k, v)
        @@redis.expire(k, ttl) if ttl
      end
    end
    
    def getset(k, v)
      @@redis.getset(k, v)
    end
    
    def keys(k)
      @@redis.keys(k)
    end
    
    def del(k)
      @@redis.del(k)
    end
    
    def expire(k, ttl)
      @@redis.expire(k, ttl)
    end
    
    def incr(k)
      @@redis.incr(k)
    end
    
  end
  
end