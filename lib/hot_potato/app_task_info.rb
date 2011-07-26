require "socket"

class AppTaskInfo 
  
  include HotPotato::Core
  
  def initialize(options = {})
    @data = {}
    @data[:started_at] = options[:started_at] || Time.now
    @data[:updated_at] = options[:updated_at] || @data[:started_at]
    @data[:hostname]   = options[:hostname]   || Socket.gethostname
    @data[:classname]  = options[:classname]  || "AppTask"
    @data[:pid]        = options[:pid]        || Process.pid
  end
  
  def key 
    "hotpotato.apptask.#{@data[:hostname]}.#{@data[:classname]}.#{@data[:pid]}"
  end

  def to_s
    @data.to_s
  end
  
  def type
    return "Faucet" if Kernel.const_get(@data[:classname]).ancestors.include?(HotPotato::Faucet)
    return "Worker" if Kernel.const_get(@data[:classname]).ancestors.include?(HotPotato::Worker)
    return "Sink"   if Kernel.const_get(@data[:classname]).ancestors.include?(HotPotato::Sink)    
  end
  
  def classname
    @data[:classname]
  end
  
  def hostname
    @data[:hostname]
  end

  def requests_in
    stat.get("hotpotato.counter.apptask.#{@data[:hostname]}.#{@data[:classname]}.#{@data[:pid]}.messages_in") || 0
  end

  def requests_out
    stat.get("hotpotato.counter.apptask.#{@data[:hostname]}.#{@data[:classname]}.#{@data[:pid]}.messages_out") || 0
  end

  def pid
    @data[:pid].to_i
  end
  
  def started_at
    return nil unless @data[:started_at]
    DateTime.parse(@data[:started_at])
  end
  
  def updated_at
    return nil unless @data[:updated_at]
    DateTime.parse(@data[:updated_at])
  end
  
  def touch
    @data[:updated_at] = Time.now
  end
  
  def to_json(*a)
    result = @data
    result["json_class"] = self.class.name
    result.to_json(*a)
  end
  
  def self.json_create(o)
    options = {}
    options[:started_at] = o["started_at"]
    options[:updated_at] = o["updated_at"]
    options[:pid]        = o["pid"]
    options[:classname]  = o["classname"]    
    options[:hostname]   = o["hostname"]    
    new options
  end
  
end