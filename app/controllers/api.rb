get '/info.json' do
  @files, callback = params[:file], params[:callback]

  unless @files.blank?
    json = {}

    @files = [ @files ] if @files.is_a?(String) # Convert to array...
    @files.slice!(0..9) if @files.length > 10
    @files.each do |f|
      fi = RequestFile.first(:uuid => f) rescue nil
      unless fi.blank?
        # json[f] = {:file => fi.file_name, :requests_count => fi.total_requests}
        json[f] = {:requests_count => fi.total_requests}
      else
        json[f] = nil
      end
    end
  else
    json = {:error => 'There are no requests to parse.'}
  end

  str = json.to_json
  str = "#{callback}(#{str});" unless callback.blank?

  str
end