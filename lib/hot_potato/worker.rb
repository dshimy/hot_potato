module HotPotato
  
  # Workers manipulate data from other workers or faucets.  Examples include: Calculate Scores, Merge 
  # Data, and Filter Data.  Each worker is a ruby file in the app directory that extends HotPotato::Worker
  # and implements the perform(message) method.  For each message the worker wants to send to the next AppTask,
  # the send_message method should be called.
  # 
  #     class Influencer < HotPotato::Worker
  # 
  #       def perform(message)
  #         message["influence"] = rand(100)
  #         send_message message
  #       end
  # 
  #     end
  class Worker
    
    include HotPotato::AppTask
    
    def start(queue_in)
      @queue_out = underscore(self.class.name.to_sym)
      if !self.respond_to?('perform')
        log.error "The Worker #{self.class.name} does not implement a perform method."
        exit 1
      end
      start_heartbeat_service      
      queue_subscribe(queue_in) do |m|
        count_message_in
        perform m
      end
    end
    
    def send_message(m)
      queue_inject @queue_out, m
      count_message_out
    end
    
  end
  
end