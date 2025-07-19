require "opensearch"

# Configure global OpenSearch client
OPENSEARCH_CLIENT = OpenSearch::Client.new(
  hosts: [ {
    host: "localhost",
    port: 9200,
    user: "admin",
    password: "Hey@345#&&",
    scheme: "https"
  } ],
  transport_options: {
    ssl: {
      verify: false # Disable SSL verification - only for development
    }
  }
)
