class JobTest1Job < ApplicationJob
  queue_as :default

  # SolidQueue-based implementation for OpenSearch indexing
  def perform(document)
    index_name = OpensearchIndexCreator::INDEX_NAME

    # Index the document in OpenSearch
    OPENSEARCH_CLIENT.index(
      index: index_name,
      id: document[:id],
      body: document
    )

    # Log for debugging
    Rails.logger.info("JobTest1Job (SolidQueue): Indexed document #{document[:id]}")
  end
end
