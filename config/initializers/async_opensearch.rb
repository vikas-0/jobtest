require 'async/http/internet/instance'
require 'json'
require 'uri'
require 'base64'
require 'async'

# An async-compatible OpenSearch client that works with AsyncJob
class AsyncOpenSearchClient
  def initialize(url, username: nil, password: nil, ssl_verify: true)
    @base_url = url
    @username = username
    @password = password
    @ssl_verify = ssl_verify ? true : false
  end

  def index(index:, id: nil, body:)
    # Extract or generate a job ID to track this specific request
    job_id = id || SecureRandom.uuid

    path = "/#{index}/_doc"
    path = "#{path}/#{job_id}" if job_id

    # Prepare headers
    headers = prepare_headers

    # Prepare URL
    uri = URI.parse(@base_url)
    url = "#{uri.scheme}://#{uri.host}:#{uri.port}#{path}"

    # Prepare body
    json_body = JSON.dump(body)

    # Return an Async task that will perform the request asynchronously
    # This allows multiple requests to be processed concurrently
    Async do |task|
      # Add artificial delay to simulate high-latency operations
      # This will demonstrate the benefits of async processing
      # sleep(3)

      response = nil
      result = nil

      begin
        # Log the request details for debugging
        Rails.logger.info("AsyncJob OpenSearch Request to: #{url}")
        Rails.logger.info("AsyncJob OpenSearch Headers: #{headers.inspect}")

        # Make the request asynchronously
        response = Async::HTTP::Internet.post(url, headers, json_body)

        # Check response status
        if response.status == 200 || response.status == 201
          # Parse the response
          result = JSON.parse(response.read, symbolize_names: true)

          # Log the successful response
          Rails.logger.info("AsyncJob OpenSearch Response for job #{job_id}: #{result.inspect}")

          # Mark this job as completed in the Redis job tracker
          RedisJobTracker.increment_completed("AsyncJob")

          # Get current counts from Redis
          completed = RedisJobTracker.get_completed_count("AsyncJob")
          total = RedisJobTracker.get_total_jobs("AsyncJob")

          # Log completion status
          Rails.logger.info("AsyncJob Job Completion: #{completed}/#{total} jobs completed")
        else
          # Log error response
          error_body = response.read
          Rails.logger.error("AsyncJob OpenSearch Error for job #{job_id}: Status #{response.status}, Body: #{error_body}")

          # Still mark as completed to avoid hanging the benchmark
          RedisJobTracker.increment_completed("AsyncJob")

          # Return error information
          result = { error: true, status: response.status, body: error_body }
        end
      rescue => e
        # Log any exceptions
        Rails.logger.error("AsyncJob OpenSearch Exception for job #{job_id}: #{e.class} - #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))

        # Still mark as completed to avoid hanging the benchmark
        RedisJobTracker.increment_completed("AsyncJob")

        # Return error information
        result = { error: true, exception: e.class.name, message: e.message }
      ensure
        # Ensure response is closed if it exists
        response&.close
      end

      # Return the result from the async task
      result
    end
  end
  private

  def prepare_headers
    headers = [
      ['content-type', 'application/json'],
      ['accept', 'application/json']
    ]

    # Add basic auth if credentials provided
    if @username && @password
      auth = "#{@username}:#{@password}"
      # Make sure the authorization header is properly formatted
      headers << ['authorization', "Basic #{Base64.strict_encode64(auth)}"]

      # For debugging
      Rails.logger.info("AsyncOpenSearchClient: Using authentication with username: #{@username}")
    else
      Rails.logger.warn("AsyncOpenSearchClient: No authentication credentials provided!")
    end

    headers
  end
end

# Create a global instance for use in jobs
# Use the same credentials as the regular OpenSearch client
ASYNC_OPENSEARCH_CLIENT = AsyncOpenSearchClient.new(
  'https://localhost:9200',
  username: 'admin',
  password: 'Hey@345#&&',
  ssl_verify: false
)

# Log the client initialization
Rails.logger.info("AsyncOpenSearchClient initialized with URL: https://localhost:9200 and username: admin")
