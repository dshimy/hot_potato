require 'ostruct'
require 'optparse'
require 'socket'

module HotPotato
  
  # This is used internally.
  class AppTaskServer
    
    include HotPotato::Core
    
    def initialize
      @options = load_options
      @options.app_task_name, @options.mode = parse_options 
      trap("INT") { shutdown }
      self.send(@options.mode)
    end
    
    def start
      set_logger(:queue_logger, :classname => classify(app_task_name))
      Process.daemon
      STDIN.reopen '/dev/null'
      STDOUT.sync = true
      STDERR.sync = true
      run
    end
    
    def run
      $0 = "Hot Potato AppTask [#{classify(@options.app_task_name)}]"
      log.info "Starting Hot Potato AppTask #{HotPotato::VERSION} #{classify(@options.app_task_name)}"
      app_task = @options.routes.find @options.app_task_name
      if app_task
        obj = Kernel.const_get(classify(app_task.classname)).new
        begin
          if app_task.source
            obj.start app_task.source
          else
            obj.start
          end
        rescue Exception
          log.fatal $!
          exit 1
        end
      else
        puts "Could not find #{@options.app_task_name} in the route definition"
        exit 1
      end
    end
    
    def parse_options
      mode = :run
      app_task_name = ""
      op = OptionParser.new do |opts|
        opts.banner = "Usage: #{$0} app_task_name [run|start]"
        opts.on_tail("-h", "--help", "Show this message") do
          puts op
          exit!
        end
      end
      begin
        op.parse!
        app_task_name = ARGV.shift
        mode = (ARGV.shift || "run").to_sym
        if ![:start, :run].include?(mode)
          puts op
          exit!
        end
      rescue
        puts op
        exit!
      end
      return app_task_name, mode
    end
    
    def shutdown
      log.info "Stopping AppTask..."
      exit!
    end
    
    def load_options
      options = OpenStruct.new
      options.mode          = :run
      options.hostname      = Socket.gethostname
      options.routes        = HotPotato::Route.routes
      options.app_task_name = ""
      
      return options
    end
    
  end
  
end