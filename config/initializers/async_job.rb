require "async/job/processor/redis"
require "async/job/processor/inline"
require "redis"

Rails.application.configure do
  puts "Configuring AsyncJob..."
  
  # For benchmarking purposes, always use the Inline processor
  # This avoids Redis connection issues and allows us to focus on measuring
  # the performance differences between SolidQueue and AsyncJob
  puts "Using Inline processor for AsyncJob"
  
  # Create a queue for the "default" backend with Inline processor
  config.async_job.define_queue "default" do
    dequeue Async::Job::Processor::Inline
  end
  
  # Create a queue named "local" which also uses the Inline backend
  config.async_job.define_queue "local" do
    dequeue Async::Job::Processor::Inline
  end

  puts "AsyncJob configured with Inline processor for benchmarking"
  
  # Set Async::Job as the global Active Job queue adapter:
  # config.active_job.queue_adapter = :async_job
end
