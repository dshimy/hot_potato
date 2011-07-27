require 'ostruct'
require 'optparse'
require 'socket'

module HotPotato
  
  # The supervisor is a process that runs on each machine that participates in the cluster.
  # When it starts it does the following:
  # 
  # 0. Read the routes file
  # 1. Connect to the Redis server and get the appTask process ID table
  # 2. Acquire the global lock
  # 3. If a process is needed, fork a new process for AppTask
  # 4. Release the global lock
  # 5. Rinse and Repeat
  # 
  # The supervisor also starts the Heartbeat service and logging service as background threads.
  # 
  # The supervisor can be managed from the command line:
  # 
  #     $ bin/supervisor [run|start|stop|restart]
  # 
  # If started without any settings, it will default to run.
  class SupervisorServer

    include HotPotato::Core

    MAX_APP_TASKS      = 32
    HEARTBEAT_INTERVAL = 20
    PID_FILE           = "#{APP_PATH}/tmp/supervisor.pid"
    LOG_FILE           = "#{APP_PATH}/logs/supervisor.log"
    
    def initialize
      @options      = load_options
      @options.mode = parse_options 
      trap("INT") { shutdown }
      self.send(@options.mode)
    end
        
    def run
      $0 = "Hot Potato Supervisor"
      log.info "Starting Hot Potato Supervisor #{HotPotato::VERSION}"
      begin
        start_heartbeat_service
        start_log_service
        routes = HotPotato::Route.routes
        while @options.running do       
          if acquire_lock :supervisor
            log.debug "Lock acquired"          
            routes.app_tasks.each do |app_task|
              if app_task.running_instances < app_task.instances && app_task.allow_group(@options.group)
                if has_capacity
                  log.info "Starting AppTask [#{classify(app_task.classname)}]"
                  pid = fork do
                    Process.setsid
                    exec "#{APP_PATH}/bin/app_task #{app_task.classname.to_s}"
                  end
                  Process.detach pid
                  sleep 2
                else
                  log.warn "Cannot start AppTask [#{app_task.classname}] - Server at Capacity (Increase max_app_tasks)"
                end
              end
            end            
            release_lock :supervisor        
          end
          sleep (5 + rand(5))
        end
      rescue Exception
        log.error $!
        log.error $@
        exit 1
      end
    end    
    
    def start
      # Check if we are running
      if File.exists?(PID_FILE)
         pid = 0;
         File.open(PID_FILE, 'r') do |f|
            pid = f.read.to_i
         end
         # Check if we are REALLY running
         if Process.alive?(pid)
           log.fatal "Supervisor is already running on this machine.  Only one instance can run per machine."
           exit 1
         else
           log.info "Supervisor is not running despite the presence of the pid file.  I will overwrite the pid file and start the supervisor."
         end
      end
      Process.daemon
      File.open(PID_FILE, 'w') do |f|
        f.write "#{Process.pid}\n"
      end    
      STDIN.reopen '/dev/null'
      STDOUT.reopen LOG_FILE, 'a'
      STDERR.reopen STDOUT
      STDOUT.sync = true
      STDERR.sync = true
      run
    end
    
    # Stops the Supervisor.  Requires the existance of a PID file.
    # Calls the shutdown hook to stop AppTasks.
    def stop
      pid = 0
      shutdown      
      if File.exists?(PID_FILE)
        File.open(PID_FILE, 'r') do |f|
          pid = f.read.to_i
        end              
        Process.kill("INT", pid) if Process.alive?(pid)
        File.delete(PID_FILE)
      else
        log.fatal "Supervisor PID file does not exist."
        exit 1
      end
    end
    
    # Restarts the Supervisor
    def restart
      stop
      sleep 2
      start
    end
    
    def parse_options
      mode = :run
      op = OptionParser.new do |opts|
        opts.banner = "Usage: #{$0} [run|start|stop|restart]"
        opts.on_tail("-h", "--help", "Show this message") do
          puts op
          exit
        end
      end
      begin
        op.parse!
        mode = (ARGV.shift || "run").to_sym
        if ![:start, :stop, :restart, :run].include?(mode)
          puts op
          exit 1
        end
      rescue
        puts op
        exit 1
      end
      return mode
    end
    
    # Kills any running AppTasks on this machine and removes entries from the 
    # process table cache.  Removes entry for the supervisor in the process
    # table cache.
    def shutdown
      @options.running = false      
      stat.keys("hotpotato.apptask.#{@options.hostname}.*").each do |app_task_key|
        app_task = JSON.parse(stat.get(app_task_key))
        log.info "Killing PID #{app_task.pid} [#{app_task.classname}]"
        Process.kill("INT", app_task.pid) if Process.alive?(app_task.pid)
        stat.del app_task_key
      end
      stat.keys("hotpotato.supervisor.#{@options.hostname}.*").each do |supervisor_key|
        stat.del supervisor_key
      end
      log.info "Stopping Supervisor..."
    end
   
    # Determines if this host reached the limit of the number of AppTasks it
    # can run
    def has_capacity
      return stat.keys("hotpotato.apptask.#{@options.hostname}.*").count < @options.max_app_tasks
    end
    
    # OK, this is not really a log service, but it is responsible for subscribing to the log messages
    # from the AppTasks on this server.
    def start_log_service
      Thread.new do
        log.info "Thread created for Supervisor [Log]"
        queue_subscribe("hotpotato.log.#{@options.hostname}") do |m|
          log_entry = JSON.parse(m)
          if log.respond_to?(log_entry["severity"].to_sym)
            log.send(log_entry["severity"].to_sym, "#{log_entry['classname']} [#{log_entry['pid']}] - #{log_entry['message']}")
          end
        end
      end
    end
    
    # Starts a background thread to update the process list in redis.
    def start_heartbeat_service
      si = SupervisorInfo.new
      stat.set si.key, si.to_json
      stat.expire si.key, 120

      Thread.new do
        log.info "Thread created for Supervisor [Heartbeat]"
        loop do
          si.touch
          stat.set si.key, si.to_json, 120
          sleep HEARTBEAT_INTERVAL
        end
      end
    end

    # Loads the options, mainly from the config.yml file, into an OpenStruct object.
    def load_options
      options = OpenStruct.new
      options.max_app_tasks = MAX_APP_TASKS
      options.group         = ""
      options.mode          = :run
      options.hostname      = Socket.gethostname
      options.running       = true
      
      if config["servers"]
        config["servers"].each do |server|
          if server["hostname"] == options.hostname
            options.max_app_tasks = server["max_app_tasks"] || MAX_APP_TASKS
            options.group         = server["group"]         || ""
            break
          end
        end
      end
      return options
    end

  end

end