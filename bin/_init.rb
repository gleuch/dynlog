BIN_PATH = File.expand_path(File.dirname(__FILE__)) if !defined?(BIN_PATH) || BIN_PATH.empty?
ROOT_PATH = File.expand_path(File.dirname(__FILE__) + '/..') if !defined?(ROOT_PATH) || ROOT_PATH.empty?
LOG_FILE = 'scripts' if !defined?(LOG_FILE) || LOG_FILE.empty?


# Requires
require 'rubygems'
require 'bundler'
Bundler.require

# Base setup
set :environment, :production

# Log setup
log = File.new("#{ROOT_PATH}/log/#{LOG_FILE}.log", "a")
STDERR.reopen(log)

# Requires...
%w(configatron digest/md5 base64 dm-core dm-types dm-timestamps dm-aggregates dm-ar-finders).each{|lib| require lib.gsub(/ROOT/, ROOT_PATH)}

# Configatron settings
configatron.configure_from_yaml("#{ROOT_PATH}/config.yml", :hash => Sinatra::Application.environment.to_s)
configatron.directory_path = '' if configatron.directory_path == '/' # HARD Rewrite
configatron.tmp_path = configatron.tmp_path.gsub(/ROOT/, ROOT_PATH)

# Database setup
%w(all).each{|lib| require "#{ROOT_PATH}/app/models/all"}
DataMapper.setup(:default, configatron.db_connection.gsub(/ROOT/, ROOT_PATH))
DataMapper.auto_upgrade!


def rand_str(len=32)
  o =  'abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789-_'.split('')
  return (0..len).map{ o[rand(o.length)]  }.join
end
  


def err(msg, stop=false)
  # Tell us in command line...
  tell " "
  tell "--------------------------------"
  tell "An error has occurred:"
  tell "   - #{msg}"
  tell " "

  # Log in!
  STDERR.puts "[#{Time.now}] #{msg}"

  # Exit if requested
  if stop
    tell "STOPPING!"
    exit
  end
end

def tell(msg)
  STDOUT.puts "[#{Time.now}] #{msg}"
end