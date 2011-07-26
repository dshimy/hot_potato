require 'test/unit'
$LOAD_PATH << File.dirname(__FILE__) + '/../lib/'

APP_PATH ||= File.expand_path('..', __FILE__)
RACK_ENV ||= 'test'

require 'hot_potato'
