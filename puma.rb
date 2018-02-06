require 'yaml'

conf = YAML.load_file('config.yaml')

stdout_redirect 'log/stdout.log', 'log/stderr.log', true
environment 'production'
daemonize conf['daemonize']
pidfile './puma.pid'
bind "tcp://#{conf['bind_address']}:#{conf['port']}"
workers 2
