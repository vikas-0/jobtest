class JobTest2Job < ApplicationJob
  self.queue_adapter = :async_job
  queue_as :default

  # AsyncJob-based implementation for OpenSearch indexing with async HTTP
  # Now processes a single document instead of a batch
  def perform(document)
    job_id = SecureRandom.uuid

    # Record start metrics
    ResourceMetricsService.record_start(:async_job, job_id)

    begin
      index_name = OpensearchIndexCreator::INDEX_NAME

      # Index the single document using async HTTP client
      # The index method now returns an Async task that we need to wait for
      task = ASYNC_OPENSEARCH_CLIENT.index(
        index: index_name,
        id: document[:id],
        body: document
      )

      # Wait for the task to complete and get the result
      # This allows other fibers to run while we're waiting
      # result = task.wait

      # Log for debugging
      Rails.logger.info("JobTest2Job (AsyncJob): Indexed document using async HTTP with result: #{result.inspect}")
    ensure
      # Record end metrics
      ResourceMetricsService.record_end(:async_job, job_id)
    end
  end
end
