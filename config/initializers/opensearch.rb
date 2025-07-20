require "opensearch"

# Configure the base OpenSearch client
BASE_OPENSEARCH_CLIENT = OpenSearch::Client.new(
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

# Create a wrapper class that adds a delay to simulate high-latency operations
class DelayedOpenSearchClient
  def initialize(client, delay_seconds = 3)
    @client = client
    @delay_seconds = delay_seconds
  end

  def index(options = {})
    # Extract or generate a job ID to track this specific request
    job_id = options[:id] || SecureRandom.uuid

    # Add artificial delay to simulate network latency
    # sleep(@delay_seconds)

    # Call the underlying client and get the response
    response = @client.index(options)

    # Log the response
    Rails.logger.info("SolidQueue OpenSearch Response for job #{job_id}: #{response.inspect}")

    # Mark this job as completed in the Redis job tracker
    RedisJobTracker.increment_completed("SolidQueue")

    # Get current counts from Redis
    completed = RedisJobTracker.get_completed_count("SolidQueue")
    total = RedisJobTracker.get_total_jobs("SolidQueue")

    # Log completion status
    Rails.logger.info("SolidQueue Job Completion: #{completed}/#{total} jobs completed")

    # Return the response
    response
  end

  # Forward other methods to the underlying client
  def method_missing(method_name, *args, &block)
    @client.send(method_name, *args, &block)
  end

  def respond_to_missing?(method_name, include_private = false)
    @client.respond_to?(method_name, include_private) || super
  end
end

# Create the delayed client for use in jobs
OPENSEARCH_CLIENT = DelayedOpenSearchClient.new(BASE_OPENSEARCH_CLIENT)
