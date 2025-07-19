class JobTest2Job < ApplicationJob
  self.queue_adapter = :async_job
  queue_as :default

  # AsyncJob-based implementation for OpenSearch indexing
  def perform(documents)
    job_id = SecureRandom.uuid

    # Record start metrics
    ResourceMetricsService.record_start(:async_job, job_id)

    begin
      index_name = OpensearchIndexCreator::INDEX_NAME

      # Index each document in OpenSearch
      documents.each do |document|
        OPENSEARCH_CLIENT.index(
          index: index_name,
          id: document[:id],
          body: document
        )
      end

      # Log for debugging
      Rails.logger.info("JobTest2Job (AsyncJob): Indexed documents")
    ensure
      # Record end metrics
      ResourceMetricsService.record_end(:async_job, job_id)
    end
  end
end
