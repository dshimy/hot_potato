require "socket"

module HotPotato
  
  # AppTasks are the controllers in the framework.  The Supervisor (See below) is responsible for
  # starting AppTasks.  There are three types: Faucets, Workers, and Sinks.
  module AppTask
   
   HEARTBEAT_INTERVAL = 20
   
   include HotPotato::Core
   
   # Used to keep AppTask statistics when a message is received.
   def count_message_in
     stat.incr "hotpotato.counter.apptask.#{Socket.gethostname}.#{self.class.name}.#{Process.pid}.messages_in"
     stat.expire "hotpotato.counter.apptask.#{Socket.gethostname}.#{self.class.name}.#{Process.pid}.messages_in", 600
   end
   
   # Used to keep AppTask statistics when a message is sent.
   def count_message_out
     stat.incr "hotpotato.counter.apptask.#{Socket.gethostname}.#{self.class.name}.#{Process.pid}.messages_out"     
     stat.expire "hotpotato.counter.apptask.#{Socket.gethostname}.#{self.class.name}.#{Process.pid}.messages_out", 600
   end
   
   # Starts the HeartBeat service to maintain the process id table.
   def start_heartbeat_service
     ati = AppTaskInfo.new(:classname => self.class.name)
     stat.set ati.key, ati.to_json, 120

     Thread.new do
       log.info "Thread created for AppTask [Heartbeat]"
       loop do
         ati.touch
         stat.set ati.key, ati.to_json, 120
         sleep HEARTBEAT_INTERVAL
       end
     end
   end
    
  end
  
end