require 'fileutils'

module HotPotato
  
  class Generate
    
    def initialize(app_path) 
      @app_path = app_path   
      log "Generating application #{@app_path}..."
      mkdir app_path    
      copy_file "Gemfile"
      copy_file "Rakefile"
      mkdir "app"
      mkdir "bin"
      copy_file "admin", 'bin', 0755
      copy_file "app_task", 'bin', 0755
      copy_file "generate", 'bin', 0755
      copy_file "supervisor", 'bin', 0755
      mkdir "config"
      mkdir "config/environments"
      copy_file "development.rb", 'config/environments'
      copy_file "test.rb", 'config/environments'
      copy_file "production.rb", 'config/environments'
      copy_file "boot.rb", 'config'
      copy_file "config.yml", 'config'
      copy_file "routes.rb", 'config'   
      mkdir "docs"
      mkdir "logs"
      mkdir "test"
      mkdir "tmp"
    end

    def mkdir(path)
      dir = path == @app_path ? @app_path : "#{@app_path}/#{path}"
      if Dir.exists?(dir)
        log "     exist  #{dir}"
      else
        Dir.mkdir(dir)
        log "    create  #{dir}"
      end
    end
    
    def copy_file(src, dest = "", perm = 0644)
      dest = "#{dest}/" unless dest == ""
      log "    add     #{@app_path}/#{dest}#{src}"
      FileUtils.cp "#{File.expand_path('..', __FILE__)}/templates/#{src}", "#{@app_path}/#{dest}#{src}"
      File.chmod perm, "#{@app_path}/#{dest}#{src}"
    end
    
    def log(message)
      puts "#{message}"
    end
    
  end
  
end