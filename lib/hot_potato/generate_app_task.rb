module HotPotato
  
  class GenerateAppTask
   
    def initialize
      usage unless ARGV[1]
      name = underscore(ARGV[1])
      
      case ARGV[0]
      when "sink"
        process_template "template_sink.rb", "#{name}.rb", classify(name)
      when "faucet"
        process_template "template_faucet.rb", "#{name}.rb", classify(name)
      when "worker"
        process_template "template_worker.rb", "#{name}.rb", classify(name)
      else
        usage
      end
    end
    
    def usage
      puts "Usage: generate [faucet|worker|sink] name"
      exit 1      
    end
    
    def process_template(src, dest, name)

      template_file = File.open("#{File.expand_path('..', __FILE__)}/templates/#{src}")
      contents = ""
      template_file.each { |line| contents << line}

      result = contents.gsub("__NAME__", name)
      dest_file = File.new("#{APP_PATH}/app/#{dest}", "w")
      dest_file.write(result)
      dest_file.close
      puts "Writing #{APP_PATH}/app/#{dest}"
    end
    
  end
  
end