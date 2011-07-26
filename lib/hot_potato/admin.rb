require 'sinatra/base'
require 'redis'
require 'erb'

module HotPotato

  # The admin server is a Sinatra-based application to display statistical and diagnostic information.
  # 
  # The admin server can be managed from the command line:
  # 
  #     $ bin/admin --help
  # 
  #     Usage: ./admin [options]
  # 
  #     Vegas options:
  #       -K, --kill               kill the running process and exit
  #       -S, --status             display the current running PID and URL then quit
  #       -s, --server SERVER      serve using SERVER (thin/mongrel/webrick)
  #       -o, --host HOST          listen on HOST (default: 0.0.0.0)
  #       -p, --port PORT          use PORT (default: 5678)
  #       -x, --no-proxy           ignore env proxy settings (e.g. http_proxy)
  #       -e, --env ENVIRONMENT    use ENVIRONMENT for defaults (default: development)
  #       -F, --foreground         don't daemonize, run in the foreground
  #       -L, --no-launch          don't launch the browser
  #       -d, --debug              raise the log level to :debug (default: :info)
  #           --app-dir APP_DIR    set the app dir where files are stored (default: ~/.vegas/Hot_Potato_Admin_Server)/)
  #       -P, --pid-file PID_FILE  set the path to the pid file (default: app_dir/Hot_Potato_Admin_Server.pid)
  #           --log-file LOG_FILE  set the path to the log file (default: app_dir/Hot_Potato_Admin_Server.log)
  #           --url-file URL_FILE  set the path to the URL file (default: app_dir/Hot_Potato_Admin_Server.url)
  # 
  #     Common options:
  #       -h, --help               Show this message
  #           --version            Show version
  # 
  # The page can be accessed at http://localhost:5678
  class Admin < Sinatra::Base
    
    include HotPotato::Core
    
    dir = File.dirname(File.expand_path(__FILE__))

    set :views,  "#{dir}/admin/views"
    set :public, "#{dir}/admin/public"
    set :static, true
    
    helpers do
      def format_date(d)
        return "" unless d
        d.strftime("%b %d, %Y %H:%M")
      end
    end
    
    get "/" do
      @machines = []
      stat.keys('hotpotato.supervisor.*').each do |key|
        @machines << JSON.parse(stat.get(key))
      end
      @apptasks = []
      stat.keys('hotpotato.apptask.*').each do |key|
        @apptasks << JSON.parse(stat.get(key))
      end
      erb :index
    end    
    
  end
  
end