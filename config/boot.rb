# Ensure subsequent requires search the correct local paths
require 'logger'
require 'honeybadger'

# Load the environment file based on Environment.  Default to development
environment = ENV['ROBOT_ENVIRONMENT'] ||= 'development'
ROBOT_ROOT = File.expand_path(File.dirname(__FILE__) + '/..')
ROBOT_LOG = Logger.new(File.join(ROBOT_ROOT, "log/#{environment}.log"))
ROBOT_LOG.level = Logger::SEV_LABEL.index(ENV['ROBOT_LOG_LEVEL']) || Logger::INFO

# config gem, without Rails, requires we load the config ourselves
require 'config'
Config.setup do |config|
  config.use_env = true
  config.env_prefix = 'SETTINGS'
  config.env_separator = '__'
end
Config.load_and_set_settings(Config.setting_files(File.dirname(__FILE__), environment))

require 'lyber_core'
LyberCore::Log.set_logfile(Settings.lybercore_log)
LyberCore::Log.set_level(ROBOT_LOG.level)

# Load Resque configuration and controller
require 'resque'
redis_url = Settings.redis.url || "localhost:6379/resque:#{environment}"
if defined? Settings.redis.timeout
  server, namespace = redis_url.split('/', 2)
  host, port, db = server.split(':')
  redis = Redis.new(host: host, port: port, thread_safe: true, db: db, timeout: Settings.redis.timeout.to_f)
  Resque.redis = Redis::Namespace.new(namespace, redis: redis)
else
  Resque.redis = redis_url
end

Dor.configure do
  workflow.url Settings.workflow.url
end

require 'zeitwerk'
loader = Zeitwerk::Loader.new
loader.push_dir(File.expand_path('lib'))
loader.setup

require 'moab'
require 'moab/stanford'
Moab::Config.configure do
  storage_roots Settings.moab.storage_roots
  storage_trunk Settings.moab.storage_trunk
  deposit_trunk Settings.moab.deposit_trunk
  path_method Settings.moab.path_method
end
