require 'yaml'

conf = YAML.load_file('config.yaml')

environment 'production'
daemonize conf['daemonize']
pidfile './puma.pid'
bind "tcp://#{conf['bind_address']}:#{conf['port']}"
workers 2
