class LogFile
  include DataMapper::Resource

  property :id,               Serial
  property :log_name,         String,   :index => :log_name
  property :path_name,        Text
  property :last_file_size,   Integer,  :default => 0
  property :last_line_at,     Integer,  :default => 0
  property :active,           Boolean,  :default => true
  property :created_at,       DateTime
  property :updated_at,       DateTime

  has n, :request_files
end

class RequestFile
  include DataMapper::Resource

  property :id,               Serial
  property :log_file_id,      Integer
  property :file_name,        Text
  property :uuid,             String,     :unique_index => :uuid
  property :parent_id,        Integer
  property :is_public,        Boolean,    :default => false
  property :active,           Boolean,    :default => true
  property :created_at,       DateTime
  property :updated_at,       DateTime

  belongs_to :log_file
  has 1, :stats, :model => 'RequestFileCachedStat'
  has n, :grouped_stats, :model => 'RequestFileStat'

  

  def total_requests
    ct = self.stats.requests_count rescue 0
    RequestFile.all(:parent_id => self.id).each{|p| ct += p.stats.requests_count rescue 0}
    return ct
  end

end


# Daily Stats
class RequestFileStat
  include DataMapper::Resource

  property :id,               Serial
  property :request_file_id,  Integer
  property :requests_count,   Integer,    :default => 0
  property :ips_count,        Integer,    :default => 0
  property :is_cached,        Boolean,    :default => false
  property :created_at,       DateTime
  property :updated_at,       DateTime

  belongs_to :request_file
end


# Overall stats (rollup)
class RequestFileCachedStat
  include DataMapper::Resource

  property :id,               Serial
  property :request_file_id,  Integer
  property :requests_count,   Integer,    :default => 0
  property :created_at,       DateTime
  property :updated_at,       DateTime

  belongs_to :request_file
end