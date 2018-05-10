environment 'production'
pidfile './puma.pid'
workers 2
worker_timeout 60
bind "tcp://#{ENV['BIND_ADDRESS']}:#{ENV['BIND_PORT']}"
