require "async/job/processor/redis"
require "async/job/processor/inline"
require "redis"

Rails.application.configure do
  config.async_job.define_queue "default" do
    dequeue Async::Job::Processor::Redis
  end

  # Create a queue named "local" which also uses the Inline backend
  config.async_job.define_queue "local" do
    dequeue Async::Job::Processor::Inline
  end

  # config.active_job.queue_adapter = :async_job
end
