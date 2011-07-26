module HotPotato
  
  # The routes file (config/routes.rb) is a Ruby DSL that does the following:
  # 
  # * Defines AppTasks (Faucets, Workers, Sinks)
  # * Defines processing chain for AppTasks
  # * Restrict AppTasks to a host group
  # * Limit number of instances
  # 
  # Example:
  # 
  #     HotPotato::Route.build do
  # 
  #       faucet :twitter_faucet
  #       worker :influencer, :source => :twitter_faucet
  #       sink :log_writer, :source => :influencer
  # 
  #     end
  #
  # Multiple sources can be attached to a worker or sink:
  # 
  #     worker :influencer, :source => [:twitter_faucet. :other_source]
  #   
  # The number of instances is set to 1.  This can be changed by setting the number of instances:
  # 
  #     worker :influencer, :source => :twitter_faucet, :instances => 2
  # 
  # AppTasks can be limited to a specific server (or set of servers) by creating a group in the 
  # config/config.yml file:
  # 
  #     development:
  #       redis_hostname: localhost
  #       redis_port: 6379
  #       servers:
  #         - hostname: worker01
  #           group: incoming
  #           max_app_tasks: 15
  #         - hostname: worker02
  #           group: worker
  #           max_app_tasks: 15
  # 
  # and specifying the group in the routes files:
  # 
  #     faucet :twitter_faucet, :group => :incoming
  module Route
    
    def self.build(&block)
      @@routes = Routes.new
      @@routes.instance_eval(&block)
    end

    def self.routes
      @@routes
    end

    class Routes
      
      attr_accessor :faucets, :workers, :sinks
  
      def initialize
        @faucets = []
        @workers = []
        @sinks = []      
      end
  
      def find(name)
        app_tasks.each do |app_task|
          if app_task.classname.to_s == name.to_s
            return app_task
          end
        end
        return nil
      end
  
      def app_tasks
        @faucets + @workers + @sinks
      end
  
      def faucet(classname, options = {}, &block)
        f = Faucet.new(classname, options)      
        f.instance_eval(&block) if block
        @faucets << f
      end
  
      def worker(classname, options = {}, &block)
        w = Worker.new(classname, options)      
        w.instance_eval(&block) if block
        @workers << w
      end
  
      def sink(classname, options = {}, &block)
        s = Sink.new(classname, options)      
        s.instance_eval(&block) if block
        @sinks << s
      end
  
      def to_s
        str = "Faucets\n"
        @faucets.each do |f|
          str << f.to_s
        end
        str << "Workers\n"
        @workers.each do |f|
          str << f.to_s
        end
        str << "Sinks\n"
        @sinks.each do |f|
          str << f.to_s
        end
        str
      end
    end

    class AppTask
      
      include HotPotato::Core
      
      attr_accessor :classname, :instances, :source, :group
      def initialize(classname, options = {})
        @classname = classname.to_s
        @instances = options[:instances] || 1
        @group     = options[:group] || ""
        if options[:source]
          if options[:source].class == Array
            @source = options[:source].map { |s| s.to_s }
          else
            @source = [options[:source].to_s]
          end
        else
          @source = nil
        end
      end
      
      def allow_group(name)
        return true if @group == ""
        return name == @group.to_s
      end
      
      def running_instances
        stat.keys("hotpotato.apptask.*.#{classify(@classname)}.*").count || 0
      end
      
      def type
        return "Faucet" if Kernel.const_get(@data[:classname]).ancestors.include?(HotPotato::Faucet)
        return "Worker" if Kernel.const_get(@data[:classname]).ancestors.include?(HotPotato::Worker)
        return "Sink"   if Kernel.const_get(@data[:classname]).ancestors.include?(HotPotato::Sink)  
        return "AppTask"  
      end
      
    end

    class Faucet < AppTask
      def to_s
        "  Faucet class [#{@classname}]\n"
      end
    end

    class Worker < AppTask
      def to_s
        "  Worker class [#{@classname}]\n"
      end
    end

    class Sink < AppTask
      def to_s
        "  Sink class [#{@classname}]\n"
      end
    end

  end
  
end