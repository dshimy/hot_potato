# Hot Potato

A Real-time Processing Framework

## Description

Hot Potato is an open source real-time processing framework written in Ruby. Originally designed to process the Twitter firehose at 3,000+ tweets per second, it has been extended to support any type of streaming data as input or output to the framework. The framework excels with applications such as, social media analysis, log processing, fraud prevention, spam detection, instant messaging, and many others that include the processing of streaming data.

## What is it?

* Written in Ruby (requires 1.9)
* Handles streaming data
* Designed for scale (can easily handle the twitter firehose on one server)
* Simple interface for writing AppTasks

# Getting Started

Start by downloading the gem (this requires Ruby 1.9):

```bash
$ gem install hotpotato
```

Next create a project:

```bash
$ hotpotato sample
Hot Potato (v0.12.1)
Generating application sample...
    create  sample
    add     sample/Gemfile
    add     sample/Rakefile
    create  sample/app
    create  sample/bin
    add     sample/bin/admin
    add     sample/bin/app_task
    add     sample/bin/supervisor
    create  sample/config
    add     sample/config/boot.rb
    add     sample/config/config.yml
    add     sample/config/routes.rb
    create  sample/docs
    create  sample/logs
    create  sample/test
    create  sample/tmp
```

## Generating AppTasks

To help with creating AppTasks, there is a generator available:

```bash
$ bin/generate [faucet|worker|sink] name
```

# The Details

## Environments

By setting the RACK_ENV environment variable, one can control which environment is loaded.
By default there are three: development, test, and production.

## AppTasks

AppTasks are the controllers in the framework.  The Supervisor (See below) is responsible for
starting AppTasks.  There are three types:

### Faucets

Faucets inject data into the system.  Examples include: Twitter Reader, SMTP, and Tail Log File.
Each faucet is a ruby file in the app directory that extends HotPotato::Faucet and implements
the perform method.  For each message received, the method should call the send_message to send
it to the next AppTask.

```ruby
class TwitterFaucet < HotPotato::Faucet

  def perform
    TweetStream::Client.new("user", "secret").sample do |s|
      message = {}
      message["username"] = s.user.screen_name
      message["text"]     = s.text
      send_message message
    end
  end

end
```

### Workers

Workers manipulate data from other workers or faucets.  Examples include: Calculate Scores, Merge 
Data, and Filter Data.  Each worker is a ruby file in the app directory that extends HotPotato::Worker
and implements the perform(message) method.  For each message the worker wants to send to the next AppTask,
the send_message method should be called.

```ruby
class Influencer < HotPotato::Worker

  def perform(message)
    message["influence"] = rand(100)
    send_message message
  end

end
```

### Sinks

Sinks send data out of the system.  Examples include: WebSocket, Database (Data Warehouse), and 
File Writer.  Each sink is a ruby file in the app directory that extends HotPotato::Sink and implements
the perform(message) method.  There is no send_message for the sink to call since it is a final destination
for the message.

```ruby
class LogWriter < HotPotato::Sink

  def perform(message)
    log.debug "#{message["username"]}:#{message["influence"]}"
  end

end
```

## Supervisor

The supervisor is a process that runs on each machine that participates in the cluster.
When it starts it does the following:

0. Read the routes file
1. Connect to the Redis server and get the appTask process ID table
2. Acquire the global lock
3. If a process is needed, fork a new process for AppTask
4. Release the global lock
5. Rinse and Repeat

The supervisor also starts the Heartbeat service and logging service as background threads.

The supervisor can be managed from the command line:

```bash
$ bin/supervisor [run|start|stop|restart]
```

If started without any settings, it will default to run.

## Admin Server

The admin server is a Sinatra-based application to display statistical and diagnostic information.

The admin server can be managed from the command line:

```bash
$ bin/admin --help

Usage: ./admin [options]

Vegas options:
  -K, --kill               kill the running process and exit
  -S, --status             display the current running PID and URL then quit
  -s, --server SERVER      serve using SERVER (thin/mongrel/webrick)
  -o, --host HOST          listen on HOST (default: 0.0.0.0)
  -p, --port PORT          use PORT (default: 5678)
  -x, --no-proxy           ignore env proxy settings (e.g. http_proxy)
  -e, --env ENVIRONMENT    use ENVIRONMENT for defaults (default: development)
  -F, --foreground         don't daemonize, run in the foreground
  -L, --no-launch          don't launch the browser
  -d, --debug              raise the log level to :debug (default: :info)
      --app-dir APP_DIR    set the app dir where files are stored (default: ~/.vegas/Hot_Potato_Admin_Server)/)
  -P, --pid-file PID_FILE  set the path to the pid file (default: app_dir/Hot_Potato_Admin_Server.pid)
      --log-file LOG_FILE  set the path to the log file (default: app_dir/Hot_Potato_Admin_Server.log)
      --url-file URL_FILE  set the path to the URL file (default: app_dir/Hot_Potato_Admin_Server.url)

Common options:
  -h, --help               Show this message
      --version            Show version
```
	
The page can be accessed at http://localhost:5678

## Routes

The routes file (config/routes.rb) is a Ruby DSL that does the following:

* Defines AppTasks (Faucets, Workers, Sinks)
* Defines processing chain for AppTasks
* Restrict AppTasks to a host group
* Limit number of instances

Example:

```ruby
HotPotato::Route.build do

  faucet :twitter_faucet
  worker :influencer, :source => :twitter_faucet
  sink :log_writer, :source => :influencer

end
```

Multiple sources can be attached to a worker or sink:

```ruby
worker :influencer, :source => [:twitter_faucet. :other_source]
```

The number of instances is set to 1.  This can be changed by setting the number of instances:

```ruby
worker :influencer, :source => :twitter_faucet, :instances => 2
```

AppTasks can be limited to a specific server (or set of servers) by creating a group in the 
config/config.yml file:

```yaml
development:
  redis_hostname: localhost
  redis_port: 6379
  servers:
    - hostname: worker01
      group: incoming
      max_app_tasks: 15
    - hostname: worker02
      group: worker
      max_app_tasks: 15
```

and specifying the group in the routes files:

```ruby
faucet :twitter_faucet, :group => :incoming
```

# Support

If you have a question try our group: http://groups.google.com/group/hotpotato-rb

If you have a bug, file it in GitHub.

# Contributing

[Fork the project](http://github.com/dshimy/HotPotato) and send pull requests.

