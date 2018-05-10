# frozen_string_literal: true

require 'puma/commonlogger'
require 'sinatra'
require 'sinatra/base'
require 'yaml'
require './lib/db'

# sinatra server for secrets
class URLShortnerServer < Sinatra::Base
  configure do
    enable :logging
    $stdout.sync = true
  end

  db = URLDB.new
  config = YAML.load_file('config.yaml')
  use Rack::Session::Cookie, key: 'rack.session',
                             path: '/',
                             secret: config['rack_session_secret']

  get '/' do
    erb :index
  end

  post '/store' do
    if params['full_url'].empty?
      redirect '/'
    else
      short_url_id = SecureRandom.urlsafe_base64(8)
      db.store_url(short_url_id, params['full_url'])
      url_port = request.port == 80 || request.port == 443 ? nil : request.port
      erb :stored, locals: { site_name: "#{request.scheme}://#{request.host}#{url_port ? ":#{url_port}" : nil}",
                             short_url_id: short_url_id }
    end
  end

  get '/:short_url_id' do
    full_url = db.get_url(params['short_url_id'])
    redirect '/' if full_url.nil? || full_url['full_url'].empty?
    redirect full_url['full_url']
  end

  not_found do
    'This is nowhere to be found.'
  end
end
