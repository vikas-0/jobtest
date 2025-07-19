require "async/job/processor/redis"
require "async/job/processor/inline"

Rails.application.configure do
  # Create a queue for the "default" backend:
  config.async_job.define_queue "default" do
    dequeue Async::Job::Processor::Redis
  end

  # Create a queue named "local" which uses the Inline backend:
  config.async_job.define_queue "local" do
    dequeue Async::Job::Processor::Inline
  end

  # Set Async::Job as the global Active Job queue adapter:
  # config.active_job.queue_adapter = :async_job
end
