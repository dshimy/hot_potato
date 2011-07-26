module HotPotato
  
  class QueueLogger
      
    include HotPotato::Core
        
    attr_accessor :level, :formatter
        
    def initialize(options = {})
      @classname = options[:classname]
    end
        
    def log(message, severity)
      log_entry = {}
      log_entry[:created_at] = Time.now
      log_entry[:message]    = message
      log_entry[:severity]   = severity
      log_entry[:host]       = Socket.gethostname
      log_entry[:pid]        = Process.pid
      log_entry[:classname]  = @classname
      
      queue_inject "hotpotato.log.#{log_entry[:host]}", log_entry.to_json
    end
  
    def debug(m); log m, __method__; end
    def info(m);  log m, __method__; end
    def warn(m);  log m, __method__; end
    def error(m); log m, __method__; end
    def fatal(m); log m, __method__; end
        
  end

end
