class OpensearchIndexCreator
  INDEX_NAME = "benchmark_test"

  def self.create_index
    return { status: "exists" } if index_exists?

    settings = {
      index: {
        number_of_shards: 1,
        number_of_replicas: 0
      }
    }

    mappings = {
      properties: {
        id: { type: "keyword" },
        title: { type: "text" },
        description: { type: "text" },
        created_at: { type: "date" },
        updated_at: { type: "date" },
        tags: { type: "keyword" },
        category: { type: "keyword" },
        status: { type: "keyword" },
        priority: { type: "integer" },
        score: { type: "float" }
      }
    }

    response = OPENSEARCH_CLIENT.indices.create(
      index: INDEX_NAME,
      body: {
        settings: settings,
        mappings: mappings
      }
    )

    { status: "created", response: response }
  end

  def self.index_exists?
    OPENSEARCH_CLIENT.indices.exists?(index: INDEX_NAME)
  end

  def self.delete_index
    if index_exists?
      OPENSEARCH_CLIENT.indices.delete(index: INDEX_NAME)
      { status: "deleted" }
    else
      { status: "not_found" }
    end
  end
end
