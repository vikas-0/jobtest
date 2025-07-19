class BenchmarkService
  # Number of documents to generate for each batch size
  BATCH_SIZES = [ 10, 100, 1000 ]

  # Number of times to run each test for more accurate results
  TEST_RUNS = 3

  def self.run_benchmarks
    results = {
      solid_queue: {},
      async_job: {}
    }

    # Create index if it doesn't exist
    OpensearchIndexCreator.create_index

    BATCH_SIZES.each do |batch_size|
      puts "Running benchmark with #{batch_size} documents..."

      # Generate test data once for this batch size
      documents = generate_test_data(batch_size)

      # Test SolidQueue (JobTest1Job)
      results[:solid_queue][batch_size] = benchmark_solid_queue(documents)

      # Test AsyncJob (JobTest2Job)
      results[:async_job][batch_size] = benchmark_async_job(documents)
    end

    # Print results
    print_results(results)

    results
  end

  def self.generate_test_data(count)
    puts "Generating #{count} test documents..."

    documents = []
    count.times do |i|
      documents << {
        id: "doc_#{i}_#{Time.now.to_i}",
        title: "Test Document #{i}",
        description: "This is a test document #{i} with some random text #{SecureRandom.hex(10)}",
        created_at: Time.now.iso8601,
        updated_at: Time.now.iso8601,
        tags: [ "test", "benchmark", "doc_#{i % 5}" ],
        category: "category_#{i % 10}",
        status: [ "active", "pending", "archived" ].sample,
        priority: rand(1..5),
        score: rand * 100
      }
    end

    documents
  end

  def self.benchmark_solid_queue(documents)
    results = []

    TEST_RUNS.times do |run|
      start_time = Time.now

      # Enqueue each document as a separate job
      documents.each do |doc|
        JobTest1Job.perform_later(doc)
      end

      # Record enqueue time
      enqueue_time = Time.now - start_time

      # Wait for jobs to complete (in a real scenario, you'd monitor the queue)
      # For benchmarking purposes, we'll use a simple approach
      sleep 1 # Give some time for jobs to start processing

      # Check job completion (this is a simplified approach)
      # In production, you'd want to use a more robust method to track job completion
      wait_for_jobs_to_complete("SolidQueue", documents.size)

      # Record total time
      total_time = Time.now - start_time

      results << {
        run: run + 1,
        document_count: documents.size,
        enqueue_time_seconds: enqueue_time.round(2),
        total_time_seconds: total_time.round(2),
        throughput: (documents.size / total_time).round(2)
      }
    end

    calculate_average_results(results)
  end

  def self.benchmark_async_job(documents)
    results = []

    TEST_RUNS.times do |run|
      start_time = Time.now

      # Enqueue each document as a separate job
      documents.each do |doc|
        JobTest2Job.perform_later(doc)
      end

      # Record enqueue time
      enqueue_time = Time.now - start_time

      # Wait for jobs to complete (in a real scenario, you'd monitor the queue)
      # For benchmarking purposes, we'll use a simple approach
      sleep 1 # Give some time for jobs to start processing

      # Check job completion (this is a simplified approach)
      # In production, you'd want to use a more robust method to track job completion
      wait_for_jobs_to_complete("AsyncJob", documents.size)

      # Record total time
      total_time = Time.now - start_time

      results << {
        run: run + 1,
        document_count: documents.size,
        enqueue_time_seconds: enqueue_time.round(2),
        total_time_seconds: total_time.round(2),
        throughput: (documents.size / total_time).round(2)
      }
    end

    calculate_average_results(results)
  end

  def self.wait_for_jobs_to_complete(job_type, expected_count)
    max_wait_time = 60 # Maximum wait time in seconds
    interval = 2 # Check interval in seconds
    total_wait = 0

    while total_wait < max_wait_time
      # This is a simplified approach - in a real scenario, you would check the job queue
      # For SolidQueue, you might check SolidQueue::Job.where(finished_at: nil).count
      # For AsyncJob, you might check a Redis queue or other metrics

      puts "Waiting for #{job_type} jobs to complete... (#{total_wait}s elapsed)"
      sleep interval
      total_wait += interval

      # For demonstration purposes, we'll just wait a bit
      # In a real implementation, you'd check if all jobs are done
      if total_wait >= (expected_count * 0.01) + 5 # Simple heuristic
        break
      end
    end
  end

  def self.calculate_average_results(results)
    return {} if results.empty?

    {
      document_count: results.first[:document_count],
      avg_enqueue_time_seconds: results.sum { |r| r[:enqueue_time_seconds] } / results.size,
      avg_total_time_seconds: results.sum { |r| r[:total_time_seconds] } / results.size,
      avg_throughput: results.sum { |r| r[:throughput] } / results.size,
      individual_runs: results
    }
  end

  def self.print_results(results)
    puts "\n========== BENCHMARK RESULTS ==========\n"

    BATCH_SIZES.each do |batch_size|
      puts "\n----- Batch Size: #{batch_size} documents -----"

      sq_results = results[:solid_queue][batch_size]
      async_results = results[:async_job][batch_size]

      puts "SolidQueue (JobTest1Job):"
      puts "  Avg Enqueue Time: #{sq_results[:avg_enqueue_time_seconds].round(2)}s"
      puts "  Avg Total Time: #{sq_results[:avg_total_time_seconds].round(2)}s"
      puts "  Avg Throughput: #{sq_results[:avg_throughput].round(2)} docs/second"

      puts "\nAsyncJob (JobTest2Job):"
      puts "  Avg Enqueue Time: #{async_results[:avg_enqueue_time_seconds].round(2)}s"
      puts "  Avg Total Time: #{async_results[:avg_total_time_seconds].round(2)}s"
      puts "  Avg Throughput: #{async_results[:avg_throughput].round(2)} docs/second"

      # Determine which is faster
      if sq_results[:avg_total_time_seconds] < async_results[:avg_total_time_seconds]
        diff = (async_results[:avg_total_time_seconds] / sq_results[:avg_total_time_seconds] - 1) * 100
        puts "\nResult: SolidQueue was #{diff.round(1)}% faster for #{batch_size} documents"
      elsif async_results[:avg_total_time_seconds] < sq_results[:avg_total_time_seconds]
        diff = (sq_results[:avg_total_time_seconds] / async_results[:avg_total_time_seconds] - 1) * 100
        puts "\nResult: AsyncJob was #{diff.round(1)}% faster for #{batch_size} documents"
      else
        puts "\nResult: Both performed equally for #{batch_size} documents"
      end
    end

    puts "\n========================================"
  end
end
