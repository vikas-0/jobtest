class JobTest2Job < ApplicationJob
  self.queue_adapter = :async_job
  queue_as :default

  # Async implementation for OpenSearch indexing
  def perform(document)
    index_name = OpensearchIndexCreator::INDEX_NAME

    # Index the document in OpenSearch
    OPENSEARCH_CLIENT.index(
      index: index_name,
      id: document[:id],
      body: document
    )

    # Log for debugging
    Rails.logger.info("JobTest2Job (AsyncJob): Indexed document #{document[:id]}")
  end
end
