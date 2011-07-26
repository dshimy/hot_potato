require "socket"

class SupervisorInfo 
  
  include HotPotato::Core
    
  def initialize(options = {})
    @data = {}
    @data[:started_at] = options[:started_at] || Time.now
    @data[:updated_at] = options[:updated_at] || @data[:started_at]
    @data[:hostname]   = options[:hostname]   || Socket.gethostname
    @data[:pid]        = options[:pid]        || Process.pid
  end
  
  def key 
    "hotpotato.supervisor.#{@data[:hostname]}.#{@data[:pid]}"
  end

  def to_s
    @data.to_s
  end
  
  def app_tasks
    stat.keys("hotpotato.apptask.#{@data[:hostname]}.*").count
  end
  
  def hostname
    @data[:hostname]
  end

  def pid
    @data[:pid]
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
    options[:hostname]   = o["hostname"]    
    new options
  end
  
end