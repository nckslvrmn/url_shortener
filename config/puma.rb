environment 'production'
pidfile './puma.pid'
workers 2
worker_timeout 60
if ENV['BIND_ADDRESS'] && ENV['BIND_PORT']
  bind "tcp://#{ENV['BIND_ADDRESS']}:#{ENV['BIND_PORT']}"
elsif ENV['BIND_SOCK']
  bind "unix://#{ENV['BIND_SOCK']}"
else
  puts "expecting BIND_ADDRESS/BIND_PORT or BIND_SOCK environment variables to bind"
  exit 1
end
