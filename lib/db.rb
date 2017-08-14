require 'sqlite3'

# controls sqlite db for secret server
class URLDB
  def initialize
    db_dir = './db'
    db_file = "#{db_dir}/url.db"
    Dir.mkdir(db_dir) unless File.directory?(db_dir)
    @db = SQLite3::Database.new(db_file) unless File.exist?(db_file)
    @db = SQLite3::Database.open(db_file)
    @db.results_as_hash = true
    @db.execute <<-SQL
    create table if not exists urls (
      short_url_id text,
      created_at text,
      full_url text
    );
    SQL
  end

  def store_url(short_url_id, full_url)
    @db.execute(
      'INSERT INTO URLS (short_url_id, created_at, full_url) VALUES (?, ?, ?)',
      [short_url_id,
       DateTime.now.to_s,
       full_url]
    )
  end

  def get_url(short_url_id)
    url = @db.execute <<-SQL
    select * from urls where short_url_id == "#{short_url_id}";
    SQL
    url[0]
  end
end
