# Goal
#   2. Web interface to see results
#   3. JSON API to allow for embeddable view counts
#   4. Documented, patched up, tested, and made be easy to run.

configure(:development) do |c|
  require 'sinatra/reloader'
  c.also_reload "*.rb"
end



configure do
  ROOT_PATH = File.expand_path(File.dirname(__FILE__)) if ROOT_PATH.blank?

  # Libraries, etc.
  # ROOT_PATH/lib/authenticate
  %w(configatron haml json dm-core dm-types dm-timestamps dm-aggregates dm-ar-finders).each{|lib| require lib.gsub(/ROOT/, ROOT_PATH)}

  # Configatron settings
  configatron.configure_from_yaml("#{ROOT_PATH}/config.yml", :hash => Sinatra::Application.environment.to_s)
  configatron.directory_path = '' if configatron.directory_path.nil? || configatron.directory_path == '/' # HARD Rewrite
  configatron.uuid_salt = 'yumtablesalt' if configatron.uuid_salt.nil?

  # Controllers and helpers
  %w(admin api public).each do |lib|
    require "#{ROOT_PATH}/app/controllers/#{lib}" # TODO : Check if exists
    require "#{ROOT_PATH}/app/helpers/#{lib}" # TODO: Check if exists
  end

  # Database setup
  %w(all).each{|lib| require "#{ROOT_PATH}/app/models/all"}
  DataMapper.setup(:default, configatron.db_connection.gsub(/ROOT/, ROOT_PATH))
  DataMapper.auto_upgrade!

  # require 'sinatra/memcached'
  # set :cache_enable, (configatron.enable_memcache && Sinatra::Application.environment.to_s == 'production')
  # set :cache_logging, false # causes problems if using w/ partials! :/

  set :sessions, true
end


helpers do
  def dev?; (Sinatra::Application.environment.to_s != 'production'); end
  # def dev?; false; end

  def partial(name, options = {})
    item_name, counter_name = name.to_sym, "#{name}_counter".to_sym
    options = {:cache => true, :cache_expiry => 300}.merge(options)

    if collection = options.delete(:collection)
      collection.enum_for(:each_with_index).collect{|item, index| partial(name, options.merge(:locals => { item_name => item, counter_name => index + 1 }))}.join
    elsif object = options.delete(:object)
      partial(name, options.merge(:locals => {item_name => object, counter_name => nil}))
    else
      path, file = name.gsub(/^(.*\/)([A-Z0-9_\-\.]+)$/i, '\1'), name.gsub(/^(.*\/)([A-Z0-9_\-\.]+)$/i, '\2')
      # unless options[:cache].blank?
      #   cache "_#{name}", :expiry => (options[:cache_expiry].blank? ? 300 : options[:cache_expiry]), :compress => false do
      #     haml "_#{name}".to_sym, options.merge(:layout => false)
      #   end
      # else
        haml "#{path}_#{file}".to_sym, options.merge(:layout => false)
      # end
    end
  end

  # Modified from Rails ActiveSupport::CoreExtensions::Array::Grouping
  def in_groups_of(item, number, fill_with = nil)
    if fill_with == false
      collection = item
    else
      padding = (number - item.size % number) % number
      collection = item.dup.concat([fill_with] * padding)
    end

    if block_given?
      collection.each_slice(number) { |slice| yield(slice) }
    else
      returning [] do |groups|
        collection.each_slice(number) { |group| groups << group }
      end
    end
  end

  def flash; @_flash ||= {}; end

  def redirect(uri, *args)
    session[:_flash] = flash unless flash.empty?
    status 302
    response['Location'] = uri
    halt(*args)
  end

end




before do
  @_flash, session[:_flash] = session[:_flash], nil if session[:_flash]

  prefix = Regexp.new("^#{configatron.directory_path}")
  not_found && halt unless prefix.match(request.path_info)
  request.path_info = request.path_info.gsub(prefix, (configatron.directory_path == request.path_info ? '/' : ''))
end



# 404 (file not found) errors
not_found do
  @error = 'Sorry, but the page you were looking for could not be found.</p><p><a href="/">Click here</a> to return to the homepage.'
  haml :fail
end

# 500 (unspecific) errors
error do
  @error = request.env['sinatra.error'].message || "You've hit an undocumented error."
  haml :fail
end