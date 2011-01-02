BIN_PATH = File.expand_path(File.dirname(__FILE__))
ROOT_PATH = File.expand_path(File.dirname(__FILE__) + '/..')
LOG_FILE = File.basename(__FILE__, '.rb')

require "#{BIN_PATH}/_init"


# Lets start grabbing and caching
begin
  tell 'Starting stats caching...'

  @stats = RequestFileStat.all(:is_cached => false) rescue nil
  unless @stats.blank?
    tell "Parsing #{@stats.count} caches..."
    @stats.each do |stat|
      @cached_stat = RequestFileCachedStat.first_or_create(:request_file_id => stat.request_file_id)
      @cached_stat.update(:requests_count => (@cached_stat.requests_count + stat.requests_count))
    end
    @stats.update(:is_cached => true)
  else
    tell 'There are no stats to cache.'
  end

  tell 'Stats caching complete!'
rescue
  err($!, true)
end