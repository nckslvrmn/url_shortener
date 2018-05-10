require 'aws-sdk-dynamodb'
require 'json'

# methods for accessing url records from db 
class URLDB
  def initialize
    @db = Aws::DynamoDB::Client.new(region: 'us-east-1', profile: 'personal')
  end

  def store_url(short_url_id, full_url)
    item = {
      short_url_id: short_url_id,
      data: {
        full_url: full_url, 
        created_at: Time.now.to_i
      }.to_json
    }
    @db.put_item(table_name: 'short_urls', item: item)
  end

  def get_url(short_url_id)
    url = @db.get_item(table_name: 'short_urls', key: { 'short_url_id' => short_url_id })
    JSON.parse(url.item['data'])
  end
end
