require 'aws-record'
require 'puma/commonlogger'
require 'sinatra'
require 'sinatra/base'

class URLDB
  include Aws::Record
  string_attr :short_url_id, hash_key: true
  string_attr :full_url
  integer_attr :created_at
  epoch_time_attr :ttl
end

# sinatra server for secrets
class URLShortenerServer < Sinatra::Base
  configure do
    enable :logging
    $stdout.sync = true
  end

  get '/' do
    erb :index
  end

  post '/store' do
    if params['full_url'].empty?
      redirect '/'
    else
      short_url_id = SecureRandom.urlsafe_base64(8)
      record = URLDB.new
      record.short_url_id = short_url_id
      record.full_url = params['full_url']
      record.created_at = Time.now.to_i
      record.ttl = (Time.now + (86400 * 30)).to_i
      record.save
      url_port = request.port == 80 || request.port == 443 ? nil : request.port
      erb :stored, locals: {
        site_name: "#{request.scheme}://#{request.host}#{url_port ? ":#{url_port}" : nil}",
        short_url_id: short_url_id
      }
    end
  end

  get '/:short_url_id' do
    record = URLDB.find(short_url_id: params['short_url_id'])
    redirect '/' if record.nil? || record.full_url.empty?
    redirect record.full_url
  end

  not_found do
    'URL not found.'
  end
end
