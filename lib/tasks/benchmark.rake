namespace :benchmark do
  desc "Run benchmark tests comparing SolidQueue and AsyncJob performance"
  task run: :environment do
    puts "Starting benchmark tests..."
    BenchmarkService.run_benchmarks
  end

  desc "Create OpenSearch index for benchmarking"
  task create_index: :environment do
    result = OpensearchIndexCreator.create_index
    puts "Index creation result: #{result[:status]}"
  end

  desc "Delete OpenSearch index used for benchmarking"
  task delete_index: :environment do
    result = OpensearchIndexCreator.delete_index
    puts "Index deletion result: #{result[:status]}"
  end
end
