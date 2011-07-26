module HotPotato
  
  # Faucets inject data into the system.  Examples include: Twitter Reader, SMTP, and Tail Log File.
  # Each faucet is a ruby file in the app directory that extends HotPotato::Faucet and implements
  # the perform method.  For each message received, the method should call the send_message to send
  # it to the next AppTask.
  # 
  #     class TwitterFaucet < HotPotato::Faucet
  # 
  #       def perform
  #         TweetStream::Client.new("user", "secret").sample do |s|
  #           message = {}
  #           message["username"] = s.user.screen_name
  #           message["text"]     = s.text
  #           send_message message
  #         end
  #       end
  # 
  #     end
  class Faucet
    
    include HotPotato::AppTask
    
    def start
      @queue_out = underscore(self.class.name.to_sym)
      if self.respond_to?('perform')
        start_heartbeat_service
        perform
      else
        log.error "The Faucet #{self.class.name} does not implement a perform method."
      end      
    end
    
    def send_message(m)
      queue_inject @queue_out, m
      count_message_out
    end
    
  end
  
end