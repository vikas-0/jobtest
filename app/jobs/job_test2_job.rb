class JobTest2Job < ApplicationJob
  self.queue_adapter = :async_job
  queue_as :default

  def perform(message)
    puts("Hello World #{message}")
    # Do something later
  end
end
