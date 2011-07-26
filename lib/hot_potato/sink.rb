module HotPotato
  
  # Sinks send data out of the system.  Examples include: WebSocket, Database (Data Warehouse), and 
  # File Writer.  Each sink is a ruby file in the app directory that extends HotPotato::Sink and implements
  # the perform(message) method.  There is no send_message for the sink to call since it is a final destination
  # for the message.
  # 
  #     class LogWriter < HotPotato::Sink
  # 
  #       def perform(message)
  #         log.debug "#{message["username"]}:#{message["influence"]}"
  #       end
  # 
  #     end
  class Sink
    
    include HotPotato::AppTask
        
    def start(queue_in)
      if !self.respond_to?('perform')
        log.error "The Sink #{self.class.name} does not implement a perform method."
        exit 1
      end
      start_heartbeat_service      
      queue_subscribe(queue_in) do |m|
        count_message_in
        perform m
      end
    end
    
  end
  
end