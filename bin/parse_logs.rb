BIN_PATH = File.expand_path(File.dirname(__FILE__))
ROOT_PATH = File.expand_path(File.dirname(__FILE__) + '/..')
LOG_FILE = File.basename(__FILE__, '.rb')

require "#{BIN_PATH}/_init"


# Lets start grabbing and logging
begin
  tell 'Starting log parsing...'
  raise 'There are no log files to parse.' if configatron.log_files.nil?
  log_files = configatron.log_files.to_hash
  
  # Lets begin parsing each log file...
  log_files.each do |log_name, log_info|
    tell "Processing #{log_name}..."
    begin
      @log, @files, @stats = nil, {}, {}
      log_file = log_info[:file].gsub(/ROOT/, ROOT_PATH)

      raise "Log file #{log_name} does not exist (#{log_file})." unless File.exists?(log_file)
      raise "Log file #{log_name} does not include a valid parse expression." if log_info[:parse].nil? || log_info[:parse].blank?
      raise "Log file #{log_name} does not include a valid parse response expression." if log_info[:response].nil? || log_info[:response].blank?

      log_match, log_replace, log_filter = Regexp.new(log_info[:parse], true), log_info[:response], false
      log_filter = Regexp.new(log_info[:filter], true) unless log_info[:filter].nil? || log_info[:filter].blank?

      # Fetch log info...
      @log = LogFile.first_or_create(:log_name => log_name) rescue nil
      @log.update(:path_name => log_file)
      raise "Cannot find or make record for #{log_name}!" if @log.blank?

      # Make a tmpfile, get info
      tmp_log_file = File.join(configatron.tmp_path, "#{log_name}.tmp")
      FileUtils.cp(log_file, tmp_log_file)
      
      # Fetch file information
      io_file = File.new(tmp_log_file, 'r')
      log_file_size, log_total_lines = io_file.size, io_file.lines.count

      # Start from zeros if new or altered log file
      @log.update(:last_line_at => 0, :last_file_size => 0) if @log.last_file_size > log_file_size || @log.last_line_at > log_total_lines
      last_line_at, last_file_size = @log.last_line_at, @log.last_file_size

      # Start parsing
      io_lines = IO.readlines(log_file)
      io_lines[last_line_at..log_total_lines].each_with_index do |line, i|
        # Filter out bad lines from log file
        if line.match(log_match)
          req_info = line.strip.gsub(log_match, log_replace)
          req = req_info.split("\t")

          # Allow filtering of requests
          if !log_filter || (log_filter && req[0].match(log_filter))
            @files[req[0]] ||= {:file => req[0], :count => 0, :timestamps => [], :ips => []}
            @files[req[0]][:count] += 1
            @files[req[0]][:timestamps] << req[1]
            @files[req[0]][:ips] << req[2] unless req[2].blank?
          end
        end
      end

      # Cleanup and track progress for next run...
      @log.update(:last_line_at => log_total_lines, :last_file_size => log_file_size)
      File.unlink(tmp_log_file) rescue nil

      tell "   - Processed #{log_name}!"
      # Start processing counts
      unless @files.blank?
        tell "   - Saving stats for #{log_name} (#{@files.length} file requests, #{log_total_lines-last_line_at} total requests)."
        @files.each do |req, info|
          @req_file = RequestFile.first_or_create(:file_name => req, :log_file_id => @log.id)
          
          # Create UUID for protected API requests
          @req_file.update(:uuid => rand_str(12)) if @req_file.uuid.blank?

          # Associate with a parent item (assuming query string is not required for uniqueness.)
          fname = req.gsub(/^(.*)(\?.*)$/i, '\1')
          unless fname == req
            @parent_req_file = RequestFile.first_or_create(:file_name => fname, :log_file_id => @log.id)
            @req_file.update(:parent_id => @parent_req_file.id)
          end

          RequestFileStat.create(:request_file_id => @req_file.id, :requests_count => info[:count], :ips_count => info[:ips].uniq.length)
        end
      else
        tell '   X There were no requests to save.'
      end

    rescue
      err($!)
    end

    tell 'Parsing complete!'
  end

rescue
  err($!, true)
end