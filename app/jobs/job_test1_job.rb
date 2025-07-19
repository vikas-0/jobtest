class JobTest1Job < ApplicationJob
  queue_as :default

  # SolidQueue-based implementation for OpenSearch indexing
  def perform(documents)
    job_id = SecureRandom.uuid

    # Record start metrics
    ResourceMetricsService.record_start(:solid_queue, job_id)

    begin
      # Simulate OpenSearch indexing
      documents.each do |document|
        # Index the document in OpenSearch
        OPENSEARCH_CLIENT.index(
          index: OpensearchIndexCreator::INDEX_NAME,
          id: document[:id],
          body: document
        )
      end
    ensure
      # Record end metrics
      ResourceMetricsService.record_end(:solid_queue, job_id)
    end

    # Log for debugging
    Rails.logger.info("JobTest1Job (SolidQueue): Indexed documents")
  end
end
