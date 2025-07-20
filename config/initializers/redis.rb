require 'redis'

# Initialize Redis client as a global variable
$redis = Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'))
